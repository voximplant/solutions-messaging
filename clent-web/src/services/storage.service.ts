import { log } from '@/utils';

const TOKEN_KEY = 'vox_token_a';
const REFRESH_TOKEN_KEY = 'vox_token_r';
const LOGIN = 'vox_login';
const ERROR = 'vox_error';

/**
 * Manage the how Access Tokens are being stored and retrieved from storage.
 *
 * Current implementation stores to localStorage. Local Storage should always be
 * accessed through this instance.
 **/

class StorageService {
  public getAccessToken() {
    return localStorage.getItem(TOKEN_KEY);
  }

  public getRefreshToken() {
    return localStorage.getItem(REFRESH_TOKEN_KEY);
  }

  public getLogin(): any {
    return localStorage.getItem(LOGIN);
  }

  public getError(): any {
    return localStorage.getItem(ERROR);
  }

  public setError(error: string): any {
    return localStorage.setItem(ERROR, error);
  }

  public removeError(): any {
    return localStorage.removeItem(ERROR);
  }

  public setTokens(auth_token: { accessToken: string; refreshToken: string }, login = '') {
    localStorage.setItem(TOKEN_KEY, auth_token.accessToken);
    localStorage.setItem(LOGIN , login);
    localStorage.setItem(REFRESH_TOKEN_KEY, auth_token.refreshToken);
  }

  public removeTokens() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
    localStorage.removeItem(LOGIN);
  }
}

export const storageService = new StorageService();
