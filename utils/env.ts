export const env = {
  baseUrl: process.env.BASE_URL ?? 'https://www.saucedemo.com',
  ci: !!process.env.CI,
} as const;
