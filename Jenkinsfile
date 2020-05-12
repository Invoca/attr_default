#!/usr/bin/groovy
@Library('jenkins-pipeline@v0.4.4')
import com.invoca.utils.*;

pipeline {
  agent {
    kubernetes {
      defaultContainer 'ruby'
      yamlFile '.jenkins/ruby_build_pod.yml'
    }
  }

  environment { GITHUB_TOKEN = credentials('github_token') }

  stages {
    stage('Setup') {
      steps {
        updateGitHubStatus('clean-build', 'pending', 'Unit tests.')
        sh 'bundle install'
        sh 'bundle exec appraisal install'
      }
    }

    stage('Appraise Current') {
      steps {
        sh 'JUNIT_OUTPUT_DIR=test/reports/current bundle exec rake'
      }
      post { always { junit 'test/reports/current/*.xml' } }
    }

    stage('Appraise Rails 4') {
      steps {
        sh 'JUNIT_OUTPUT_DIR=test/reports/rails4 bundle exec appraisal rails-4 rake'
      }
      post { always { junit 'test/reports/rails4/*.xml' } }
    }

    stage('Appraise Rails 5') {
      steps {
        sh 'JUNIT_OUTPUT_DIR=test/reports/rails5 bundle exec appraisal rails-5 rake'
      }
      post { always { junit 'test/reports/rails5/*.xml' } }
    }

    stage('Appraise Rails 6') {
      steps {
        sh 'JUNIT_OUTPUT_DIR=test/reports/rails5 bundle exec appraisal rails-6 rake'
      }
      post { always { junit 'test/reports/rails6/*.xml' } }
    }
  }

  post {
    success { updateGitHubStatus('clean-build', 'success', 'Unit tests.') }
    failure { updateGitHubStatus('clean-build', 'failure', 'Unit tests.') }
    always  { notifySlack(currentBuild.result) }
  }
}

void updateGitHubStatus(String context, String status, String description) {
  gitHubStatus([
    repoSlug:    'Invoca/attr_default',
    sha:         env.GIT_COMMIT,
    description: description,
    context:     context,
    targetURL:   env.RUN_DISPLAY_URL,
    token:       env.GITHUB_TOKEN,
    status:      status
  ])
}
