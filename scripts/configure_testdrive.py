#!/usr/bin/env python3
import os
import base64
import time
import requests


# ############################################################################
# Configure plugins in Continuum for Test Drive or Demo
# https://github.com/versionone/continuum-tools/wiki/Create-Test-Drives-in-AWS
# ############################################################################

def log_step(step, message=''):
    print(f'[x] {time.time()} [Step {step}] {message}')

def get_container_command(name):
    return f'docker container ls --quiet --filter name={name}'

def docker_command(container, command):
    return f'docker container exec {container} {command}'

# Seems like this is acting on existing data "stores-ui"
# todo: Need to automate data population
def jenkins_sed_command(_host, _file):
    return f'sed -i"" -e"s|<url>.*</url>|<url>http://{_host}/root/stores-ui.git</url>|" {_file}'

def gitlab_sed_command(_host):
    return f'sed -i"" -e"s|external_url .*$|external_url {_host}|" /etc/gitlab/gitlab.rb'

def continuum_append_command(ui_url):
    return f'echo "  ui_external_url: {ui_url}" >> /etc/continuum/continuum.yaml'


if __name__ == '__main__':

    post = requests.post
    url = 'http://localhost/api'
    host = 'not sure what perspective this is from'
    basic = base64.b64encode('administrator:password')
    headers = {'Content-Type': 'application/json',
               'Authorization': f'Basic {basic}',
               'Host': 'continuum.prod.local'}

    plugins = []

    # Step 8
    # Lifecycle plugin, adds WorkItem lookup ability
    log_step('8', 'Configuring V1 plugin in Continuum')
    plugins.append({
        'plugin': 'v1plugin',
        'name': 'default',
        'api_token': '',
        'url': '',
        'is_default': True
    })

    # Step 9
    # Gitlab plugin, for cloning repos during pipeline/task automation
    log_step('9', 'Configuring Gitlab plugin in Continuum')
    plugins.append({
        'plugin': 'gitlab',
        'name': 'gitlab',
        'api_token': '',
        'url': 'http://gitlab',
        'is_default': True
    })

    # Step 10
    # Jenkins plugin, for CI
    log_step('8', 'Configuring Jenkins plugin in Continuum')
    plugins.append({
        'plugin': 'jenkins',
        'name': 'jenkins',
        'user': 'admin',
        'password': '<comes from jenkins logs>',
        'url': 'http://jenkins',
        'is_default': True
    })

    for plugin in plugins:
        endpoint = f'{url}/configure_plugin_instance'
        response = post(endpoint, headers=headers)
        response.raise_for_status()

    # Step 7
    # add CTM url in LC
    # - allows demonstration of fixing rogue commits.

    # step 11. reference the correct continuum url (may be unnecessary)
    # Change Continuum external URL in config file
    log_step('11', 'Changing external URL in Continuum')
    continuum_container = get_container_command('continuum')
    os.system(docker_command(continuum_container, continuum_append_command(host)))

    # step 12
    # Add Continuum URL in Gitlab, pushing web hook payloads to Continuum

    # step 13
    # Configure Jenkins
    # NOTE: this needs to be done within the Jenkins container or on the mount
    jenkins_dir = '/var/lib/jenkins/jobs/'
    files = ['stores-ui/config.xml',
             'retail-site/config.xml',
             'stores-app-server/config.xml',
             'stores-app-srv/config.xml',
             'stores-ui-web/config.xml']

    log_step('13', 'Updating host in Jenkins project files')
    for f in files:
        jenkins_container = os.system(get_container_command('jenkins'))
        os.system(docker_command(jenkins_container, jenkins_sed_command(host, jenkins_dir + f)))

    # Step 14
    # Change GitLab external URL
    log_step('14', 'Changing external URL in Gitlab')
    gitlab_container = os.system(get_container_command('gitlab'))
    os.system(docker_command(gitlab_container, gitlab_sed_command(host)))

    # Step 15
    # Generate new license
    # log_step('15', 'Generating a new license')

    # Step 16
    # Set remainder or better yet, create a cron job in Continuum Production to
    # terminate the cluster
