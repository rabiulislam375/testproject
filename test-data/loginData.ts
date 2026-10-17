export const credentials = {
  valid: { username: 'standard_user', password: 'secret_sauce' },
  invalid: { username: 'invalid_user', password: 'invalid_password' },
  locked: { username: 'locked_out_user', password: 'secret_sauce' },
} as const;

export const loginErrors = {
  invalidCredentials:
    'Epic sadface: Username and password do not match any user in this service',
  lockedOut: 'Epic sadface: Sorry, this user has been locked out.',
  usernameRequired: 'Epic sadface: Username is required',
  passwordRequired: 'Epic sadface: Password is required',
} as const;
