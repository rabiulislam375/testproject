import { test, expect } from '../fixtures/testFixtures';
import { credentials, loginErrors } from '../test-data/loginData';

test.describe('SauceDemo login functionality', () => {
  test.beforeEach(async ({ loginPage }) => {
    await loginPage.goto();
  });

  test('should login successfully with valid credentials', async ({ page, loginPage }) => {
    await loginPage.login(credentials.valid.username, credentials.valid.password);

    await expect(page).toHaveURL(/.*inventory\.html/);
    await expect(page.getByText('Swag Labs')).toBeVisible();
  });

  test('should show error for invalid credentials', async ({ loginPage }) => {
    await loginPage.login(credentials.invalid.username, credentials.invalid.password);

    await expect(loginPage.errorMessage).toHaveText(loginErrors.invalidCredentials);
  });

  test('should show locked out error for locked user', async ({ loginPage }) => {
    await loginPage.login(credentials.locked.username, credentials.locked.password);

    await expect(loginPage.errorMessage).toHaveText(loginErrors.lockedOut);
  });

  test('should require username when username is empty', async ({ loginPage }) => {
    await loginPage.login('', credentials.valid.password);

    await expect(loginPage.errorMessage).toHaveText(loginErrors.usernameRequired);
  });

  test('should require password when password is empty', async ({ loginPage }) => {
    await loginPage.login(credentials.valid.username, '');

    await expect(loginPage.errorMessage).toHaveText(loginErrors.passwordRequired);
  });
});
