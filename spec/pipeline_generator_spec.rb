require_relative 'spec_helper'
require_relative '../tasks/lib/cbm/logger'
require_relative '../tasks/lib/cbm/pipeline_generator'
require 'yaml'

describe Cbm::PipelineGenerator do
  it 'generates pipeline yml' do
    uri = 'https://github.com/user/repo.git'
    branches = %w(branch1 master)
    resource_template_fixture = File.expand_path(
      '../../examples/templates/my-repo-branch-resource-template.yml.erb', __FILE__
    )
    job_template_fixture = File.expand_path(
      '../../examples/templates/my-repo-branch-job-template.yml.erb', __FILE__
    )
    subject = Cbm::PipelineGenerator.new(
      uri, branches, resource_template_fixture, job_template_fixture
    )

    expected_pipeline_yml_hash = {
      'resources' => [
        {
          'name' => 'my-repo-branch-branch1',
          'type' => 'git',
          'source' => {
            'uri' => 'https://github.com/user/repo.git',
            'branch' => 'branch1',
          },
        },
        {
          'name' => 'my-repo-branch-master',
          'type' => 'git',
          'source' => {
            'uri' => 'https://github.com/user/repo.git',
            'branch' => 'master',
          },
        },
      ],
      'jobs' => [
        {
          'name' => 'my-repo-branch-job-branch1',
          'plan' => [
            {
              'get' => 'my-repo-branch',
              'resource' => 'my-repo-branch-branch1',
              'params' => { 'depth' => 1 },
              'trigger' => true,
            },
            {
              'task' => 'my-repo-branch-task',
              'file' => 'my-repo-branch/examples/tasks/my-repo-branch-task.yml',
              'config' => {
                'params' => {
                  'BRANCH_NAME' => 'branch1',
                  'EXAMPLE_LOAD_VARS_FROM_CONFIG_KEY' =>
                    '{{EXAMPLE_LOAD_VARS_FROM_CONFIG_KEY}}',
                  'EXAMPLE_LOAD_VARS_FROM_CREDENTIALS_KEY' =>
                    '{{EXAMPLE_LOAD_VARS_FROM_CREDENTIALS_KEY}}',
                },
              },
            },
          ],
        },
        {
          'name' => 'my-repo-branch-job-master',
          'plan' => [
            {
              'get' => 'my-repo-branch',
              'resource' => 'my-repo-branch-master',
              'params' => { 'depth' => 1 },
              'trigger' => true,
            },
            {
              'task' => 'my-repo-branch-task',
              'file' => 'my-repo-branch/examples/tasks/my-repo-branch-task.yml',
              'config' => {
                'params' => {
                  'BRANCH_NAME' => 'master',
                  'EXAMPLE_LOAD_VARS_FROM_CONFIG_KEY' =>
                    '{{EXAMPLE_LOAD_VARS_FROM_CONFIG_KEY}}',
                  'EXAMPLE_LOAD_VARS_FROM_CREDENTIALS_KEY' =>
                    '{{EXAMPLE_LOAD_VARS_FROM_CREDENTIALS_KEY}}',
                },
              },
            }
          ],
        },
      ]
    }

    pipeline_file = subject.generate
    pipeline_yml = File.read(pipeline_file)

    # convert concourse pipeline param delimiters to strings so we can compare
    # as a hash for this test
    pipeline_yml.gsub!(
      '{{EXAMPLE_LOAD_VARS_FROM_CONFIG_KEY}}',
      '"{{EXAMPLE_LOAD_VARS_FROM_CONFIG_KEY}}"')
    pipeline_yml.gsub!(
      '{{EXAMPLE_LOAD_VARS_FROM_CREDENTIALS_KEY}}',
      '"{{EXAMPLE_LOAD_VARS_FROM_CREDENTIALS_KEY}}"')

    pipeline_yml_hash = YAML.load(pipeline_yml)

    expect(pipeline_yml_hash).to eq(expected_pipeline_yml_hash)
  end
end
