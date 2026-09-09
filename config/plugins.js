module.exports = ({ env }) => ({
  email: {
    config: {
      provider: 'sendmail',
      providerOptions: {
        silent: true,
        devHost: env('SMTP_HOST', 'mailpit'),
        devPort: env.int('SMTP_PORT', 1025),
      },
      settings: {
        defaultFrom: env('EMAIL_DEFAULT_FROM', 'Strapi <admin@example.com>'),
        defaultReplyTo: env('EMAIL_DEFAULT_REPLY_TO', 'Strapi <admin@example.com>'),
      },
    },
  },
});