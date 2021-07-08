let Prelude = ../../External/Prelude.dhall

let Cmd = ../../Lib/Cmds.dhall
let S = ../../Lib/SelectFiles.dhall
let D = S.PathPattern

let Pipeline = ../../Pipeline/Dsl.dhall
let JobSpec = ../../Pipeline/JobSpec.dhall

let Command = ../../Command/Base.dhall
let OpamInit = ../../Command/OpamInit.dhall
let Summon = ../../Command/Summon/Type.dhall
let Size = ../../Command/Size.dhall
let Libp2p = ../../Command/Libp2pHelperBuild.dhall
let ConnectToTestnet = ../../Command/ConnectToTestnet.dhall
let DockerImage = ../../Command/DockerImage.dhall

let dependsOn = [
  { name = "GitEnvUpload", key = "upload-git-env" },
  { name = "MinaArtifactBuster", key = "build-deb-pkg" }
 ]
let rosettaDependsOn = [ { name = "GitEnvUpload", key = "upload-git-env" } ]

in

Pipeline.build
  Pipeline.Config::{
    spec =
      JobSpec::{
        dirtyWhen = OpamInit.dirtyWhen # [
          S.strictlyStart (S.contains "src"),
          S.strictlyStart (S.contains "automation"),
          S.strictly (S.contains "Makefile"),
          S.strictlyStart (S.contains "buildkite/src/Jobs/Release/MinaArtifactBuster"),
          S.exactly "buildkite/scripts/build-artifact" "sh",
          S.exactly "buildkite/scripts/connect-to-mainnet-on-compatible" "sh",
          S.strictlyStart (S.contains "dockerfiles"),
          S.strictlyStart (S.contains "scripts")
        ],
        path = "Release",
        name = "MinaArtifactBuster"
      },
    steps = [
      Libp2p.step,
      Command.build
        Command.Config::{
          commands = OpamInit.andThenRunInDocker [
            "DUNE_PROFILE=devnet",
            "AWS_ACCESS_KEY_ID",
            "AWS_SECRET_ACCESS_KEY",
            "MINA_BRANCH=$BUILDKITE_BRANCH",
            "MINA_COMMIT_SHA1=$BUILDKITE_COMMIT",
            "MINA_DEB_CODENAME=buster",
            -- add zexe standardization preprocessing step (see: https://github.com/MinaProtocol/mina/pull/5777)
            "PREPROCESSOR=./scripts/zexe-standardize.sh"
          ] "./buildkite/scripts/build-artifact.sh",
          label = "Build Mina daemon package for Debian Buster",
          key = "build-deb-pkg",
          target = Size.XLarge,
          retries = [ Command.Retry::{ exit_status = +2, limit = Some 2 } ] -- libp2p error
        },

      -- daemon devnet image
      let daemonDevnetSpec = DockerImage.ReleaseSpec::{
        deps=dependsOn,
        deploy_env_file="export-git-env-vars.sh",
        service="mina-daemon",
        network="devnet",
        deb_codename="buster",
        step_key="daemon-devnet-buster-docker-image"
      }

      in

      DockerImage.generateStep daemonDevnetSpec,

      -- daemon mainnet image
      let daemonMainnetSpec = DockerImage.ReleaseSpec::{
        deps=dependsOn,
        deploy_env_file="export-git-env-vars.sh",
        service="mina-daemon",
        network="mainnet",
        deb_codename="buster",
        step_key="daemon-mainnet-buster-docker-image"
      }

      in

      DockerImage.generateStep daemonMainnetSpec,

      -- archive devnet image
      let archiveDevnetSpec = DockerImage.ReleaseSpec::{
        deps=dependsOn,
        deploy_env_file="export-git-env-vars.sh",
        service="mina-archive",
        deb_codename="buster",
        step_key="archive-devnet-buster-docker-image"
      }

      in

      DockerImage.generateStep archiveDevnetSpec,

      -- archive mainnet image
      let archiveMainnetSpec = DockerImage.ReleaseSpec::{
        deps=dependsOn,
        deploy_env_file="export-git-env-vars.sh",
        network="mainnet",
        service="mina-archive",
        deb_codename="buster",
        step_key="archive-mainnet-buster-docker-image"
      }

      in

      DockerImage.generateStep archiveMainnetSpec,

      -- rosetta image
      let rosettaSpec = DockerImage.ReleaseSpec::{
        deps=rosettaDependsOn,
        deploy_env_file="export-git-env-vars.sh",
        service="mina-rosetta",
        version="\\\${DOCKER_TAG}",
        commit = "\\\${GITHASH}",
        extra_args="--build-arg MINA_BRANCH=\\\${BUILDKITE_BRANCH} --build-arg MINA_REPO=\\\${BUILDKITE_PULL_REQUEST_REPO} --cache-from gcr.io/o1labs-192920/mina-rosetta-opam-deps:develop",
        deb_codename="buster",
        step_key="rosetta-mainnet-buster-docker-image"
      }

      in

      DockerImage.generateStep rosettaSpec,

      -- rosetta image w/ DUNE_PROFILE=dev
      let rosettaDuneSpec = DockerImage.ReleaseSpec::{
        deps=rosettaDependsOn,
        deploy_env_file="export-git-env-vars.sh",
        service="mina-rosetta",
        version="dev-\\\${DOCKER_TAG}",
        commit = "\\\${GITHASH}",
        extra_args="--build-arg DUNE_PROFILE=dev --build-arg MINA_BRANCH=\\\${BUILDKITE_BRANCH} --build-arg MINA_REPO=\\\${BUILDKITE_PULL_REQUEST_REPO} --cache-from gcr.io/o1labs-192920/mina-rosetta-opam-deps:develop",
        deb_codename="buster",
        step_key="rosetta-dev-buster-docker-image"
      }

      in

      DockerImage.generateStep rosettaDuneSpec
    ]
  }
