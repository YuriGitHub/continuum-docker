# Know that this is the name of the image that is built using
# scripts/deploy.sh during CI
FROM continuum:prod

# Other examples of the available base images include:

# the official production, published image
# FROM cycletime/continuum:latest

# or a custom build locally available
# FROM continuum:S-01001


# These are static env vars that make sense for Ossum, values in .env  should
# not be included in here for the sake of being included or end up in a final
# image.
ENV OSSUM true
#ENV OSSUM_OAUTH_URL ""
#ENV OSSUM_JWT_ISSUER ""
#ENV OSSUM_JWT_AUDIENCE ""
#ENV OSSUM_OAUTH_CLIENT_ID ""
#ENV OSSUM_OAUTH_SECRET ""
#ENV OSSUM_OAUTH_USERNAME ""
#ENV OSSUM_OAUTH_PASSWORD ""

#ENV APPLICATION_URL ""

ENV CONTINUUM_MONGODB_SSL true
#ENV CONTINUUM_ENCRYPTION_KEY ""
#ENV CONTINUUM_MONGODB_NAME ""
#ENV CONTINUUM_MONGODB_USERNAME ""
#ENV CONTINUUM_MONGODB_PASSWORD ""
#ENV CONTINUUM_MONGODB_AUTH ""
#ENV CONTINUUM_MONGODB_REPLICASET_HOSTS ""
#ENV CONTINUUM_MONGODB_REPLICASET_NAME ""

ENV UI_LOG_LEVEL 10
ENV JOB_HANDLER_LOG_LEVEL 10
ENV REPO_POLLER_LOG_LEVEL 10

# Disable this because we want to use
# basic auth to provision the worker
# initially and we need the administrator
# account to be open
# ENV BASIC_AUTH disabled
ENV TOKEN_AUTH disabled
ENV MSGHUB disabled

#ENV UI_EXTERNAL_URL ""
#ENV MSGHUB_EXTERNAL_URL ""
