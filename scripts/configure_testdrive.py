#!/usr/bin/env python
import os
import time
import requests


# ############################################################################
# Configure plugins in Continuum for Test Drive or Demo
# https://github.com/versionone/continuum-tools/wiki/Create-Test-Drives-in-AWS
# ############################################################################


# EC2 DNS name or IP
host = ''
# Continuum URL, from host perspective
ctm_url = 'http://localhost'
ctm_api = ctm_url + '/api'
ctm_token = '<ADMINISTRATOR_TOKEN>'
headers = {'Authorization': 'Token ' + ctm_token,
           'Content-Type': 'application/json',
           'Host': 'continuum.prod.local'}


def ping_continuum():
    for i in [.3, .7, 1.5, 3, 7, None]:
        try:
            response = requests.get(ctm_url + '/version')
            response.raise_for_status()
        except requests.exceptions.Timeout as e:
            print(str(e))
            if i is not None:
                print('Continuum server not ready, sleeping')
                time.sleep(1)
            else:
                print('Continuum server not ready, exiting')
                exit(1)


def configure_instance(payload):
    response = requests.post(ctm_api + '/configure_plugin_instance',
                             payload, headers=headers)
    response.raise_for_status()
    return response


if __name__ == '__main__':
    ping_continuum()

    # Step 7
    # add CTM url in LC
    # - allows demonstration of fixing rogue commits.

    # Step 8
    # Lifecycle plugin, adds WorkItem lookup ability
    configure_instance({
        'plugin': 'v1plugin',
        'name': 'default',
        'api_token': '',
        'url': '',
        'is_default': True
    })

    # Step 9
    # Gitlab plugin, for cloning repos during pipeline/task automation
    configure_instance({
        'plugin': 'gitlab',
        'name': 'default',
        'api_token': '',
        'url': 'http://gitlab',
        'is_default': True
    })

    # Step 10
    # Jenkins plugin, for CI
    configure_instance({
        'plugin': 'jenkins',
        'name': 'default',
        'user': 'admin',
        'password': '<comes from jenkins logs>',
        'url': 'http://jenkins',
        'is_default': True
    })

    # step 11. reference the correct continuum url (may be unnecessary)
    # Change Continuum external URL in config file
    # os.system('echo "  ui_external_url: ${value}" >> ${CONFIG_FILE}')

    # step 12
    # Add Continuum URL in Gitlab, pushing web hook payloads to Continuum

    # step 13
    # Configure Jenkins
    # NOTE: this needs to be done within the Jenkins container or on the mount


    def configure_jenkins():
        files = {
            '/var/lib/jenkins/jobs/stores-ui/config.xml': lambda host: 'sed -i"" -e"s|<url>.*</url>|<url>http://%s/root/stores-ui.git</url>|"' % host,
            '/var/lib/jenkins/jobs/retail-site/config.xml': lambda host: 'sed -i"" -e"s|<url>.*</url>|<url>http://%s/root/stores-ui.git</url>|"' % host,
            '/var/lib/jenkins/jobs/stores-app-server/config.xml': lambda host: 'sed -i"" -e"s|<url>.*</url>|<url>http://%s/root/stores-ui.git</url>|"' % host,
            '/var/lib/jenkins/jobs/stores-app-srv/config.xml': lambda host: 'sed -i"" -e"s|<url>.*</url>|<url>http://%s/root/stores-ui.git</url>|"' % host,
            '/var/lib/jenkins/jobs/stores-ui-web/config.xml': lambda host: 'sed -i"" -e"s|<url>.*</url>|<url>http://%s/root/stores-ui.git</url>|"' % host
        }

        def run_docker_command(container, command):
            return 'docker container exec %s %s' % (container, command)

        for f, rg in files.iteritems():
            cmd = rg('host') + ' ' + f
            print(run_docker_command('prod_jenkins_1', cmd))
            # os.system(run_docker_command('prod_jenkins_1', cmd))

    for cmd in [
        'sudo sed -i"" -e"s|<url>.*</url>|<url>http://' + host + '/root/stores-ui.git</url>|" /var/lib/jenkins/jobs/stores-ui/config.xml',
        'sudo sed -i"" -e"s|<url>.*</url>|<url>http://' + host + '/root/retail-site.git</url>|" /var/lib/jenkins/jobs/retail-site/config.xml',
        'sudo sed -i"" -e"s|<url>.*</url>|<url>http://' + host + '/root/stores-app-server.git</url>|" /var/lib/jenkins/jobs/stores-app-server/config.xml',
        'sudo sed -i"" -e"s|<url>.*</url>|<url>http://' + host + '/root/stores-app-srv.git</url>|" /var/lib/jenkins/jobs/stores-app-srv/config.xml',
        'sudo sed -i"" -e"s|<url>.*</url>|<url>http://' + host + '/root/stores-ui-web.git</url>|" /var/lib/jenkins/jobs/stores-ui-web/config.xml',
    ]:
        os.system(run_docker_command('prod_jenkins_1', cmd))

    # Step 14
    # Change GitLab external URL
    os.system('sudo sed -i"" -e"s|external_url .*$|external_url ' + host + '|" /etc/gitlab/gitlab.rb')

    # Step 15
    # Generate new license

    # Step 16
    # Set remainder or better yet, create a cron job in Continuum Production to
    # terminate the cluster
