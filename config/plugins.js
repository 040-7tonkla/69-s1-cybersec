module.exports = ({ env }) => ({
  email: {
    config: {
      provider: 'nodemailer',
      providerOptions: {
        host: env('EMAIL_SMTP_HOST', 'smtp.gmail.com'),
        port: env.int('EMAIL_SMTP_PORT', 465),
        secure: env.bool('EMAIL_SMTP_SECURE', true),
        auth: {
          user: env('EMAIL_SMTP_USER'),
          pass: env('EMAIL_SMTP_PASS'),
        },
      },
      settings: {
        defaultFrom: env('EMAIL_DEFAULT_FROM', 'Strapi <real922548@gmail.com>'),
        defaultReplyTo: env('EMAIL_DEFAULT_REPLY_TO', 'Strapi <real922548@gmail.com>'),
      },
    },
  },
});