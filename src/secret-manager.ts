import crypto from 'crypto';

/**
 * Decrypt a base64-encoded AES-256-GCM secret from an environment variable.
 *
 * Expected format (in the encrypted env var):
 *   base64( iv (12 bytes) || authTag (16 bytes) || ciphertext )
 *
 * The key env var should contain a strong secret. We derive a 32-byte
 * key from it using SHA-256 so you can provide any reasonably long string.
 */
export function decryptEnvSecret(
  encryptedEnvVarName: string,
  keyEnvVarName: string
): string | null {
  const encryptedValue = process.env[encryptedEnvVarName];
  if (!encryptedValue) {
    return null;
  }

  const keyRaw = process.env[keyEnvVarName];
  if (!keyRaw) {
    throw new Error(
      `${keyEnvVarName} must be set when ${encryptedEnvVarName} is provided`
    );
  }

  try {
    const buffer = Buffer.from(encryptedValue, 'base64');

    if (buffer.length < 12 + 16 + 1) {
      throw new Error('encrypted value is too short');
    }

    const iv = buffer.subarray(0, 12); // 96-bit IV for GCM
    const authTag = buffer.subarray(12, 28); // 16-byte auth tag
    const ciphertext = buffer.subarray(28);

    // Derive a 32-byte key from the raw key material
    const key = crypto.createHash('sha256').update(keyRaw).digest();

    const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
    decipher.setAuthTag(authTag);

    const decrypted = Buffer.concat([
      decipher.update(ciphertext),
      decipher.final()
    ]);

    return decrypted.toString('utf8');
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'unknown decryption error';
    throw new Error(
      `Failed to decrypt ${encryptedEnvVarName}: ${message}`
    );
  }
}

