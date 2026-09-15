FROM prawee/strapi

USER root
RUN set -ex \
 && cd /tmp \
 && npm pack @strapi/provider-email-nodemailer@4.16.2 --silent \
 && npm pack nodemailer@6 --silent \
 && mkdir -p /opt/node_modules/@strapi \
 && tar -xzf /tmp/strapi-provider-email-nodemailer-4.16.2.tgz -C /opt/node_modules/@strapi/ \
 && mv /opt/node_modules/@strapi/package /opt/node_modules/@strapi/provider-email-nodemailer \
 && tar -xzf /tmp/nodemailer-*.tgz -C /opt/node_modules/ \
 && mv /opt/node_modules/package /opt/node_modules/nodemailer \
 && rm -f /tmp/*.tgz
USER node

EXPOSE 1337
CMD ["yarn", "start"]