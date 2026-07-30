const { test, expect } = require('playwright/test');

test('avatar editor renders and plays pre-generated animation bundle', async ({ page }) => {
  const messages = [];
  const apiCalls = [];
  page.on('console', message => {
    if (message.type() === 'error' || message.type() === 'warning') {
      messages.push(`${message.type()}: ${message.text()}`);
    }
  });
  page.on('pageerror', error => messages.push(`pageerror: ${error.message}`));
  page.on('request', request => {
    const url = new URL(request.url());
    if (url.pathname.startsWith('/api/')) apiCalls.push(url.pathname);
  });

  await page.goto('http://127.0.0.1:8080/', { waitUntil: 'domcontentloaded' });
  await expect(page.locator('.avatar-preview svg')).toBeVisible({ timeout: 30000 });
  await expect(page.locator('.animation-select-field select')).toBeVisible();
  await expect(page.locator('.avatar-preview')).toHaveCount(1);
  await page.locator('.category-card summary').first().click();
  await expect(page.locator('.property-row').first()).toBeVisible();

  await page.locator('.animation-select-field select').selectOption('laughing');
  await expect(page.locator('.animation-meta')).toContainText('Tryb');
  await expect(page.locator('.animation-indicator')).toContainText(/Odtwarzanie|Ladowanie/);
  await page.getByRole('button', { name: 'Stop' }).click();
  await expect(page.locator('.animation-preview svg')).toBeVisible();
  await page.getByRole('button', { name: 'Play' }).click();
  await expect(page.locator('.animation-indicator')).toContainText(/Odtwarzanie|Ladowanie/);
  await page.getByRole('button', { name: 'Next' }).click();
  await expect(page.locator('.animation-meta')).toContainText('Tryb');

  const firstHash = ((await page.locator('.avatar-status strong').textContent()) || '').trim();
  await page.getByRole('button', { name: 'Nowy seed' }).click();
  await expect.poll(async () => {
    const nextHash = await page.locator('.avatar-status strong').textContent();
    return (nextHash || '').trim();
  }, { timeout: 30000 }).not.toBe(firstHash);
  const secondHash = ((await page.locator('.avatar-status strong').textContent()) || '').trim();
  const callsBeforePlaylistChange = apiCalls.length;
  await page.locator('.animation-select-field select').selectOption('talking');
  await expect(page.locator('.animation-indicator')).toContainText(/Odtwarzanie|Ladowanie/);
  await expect.poll(async () => {
    const currentHash = await page.locator('.avatar-status strong').textContent();
    return (currentHash || '').trim();
  }, { timeout: 15000 }).toBe(secondHash);
  expect(apiCalls.slice(callsBeforePlaylistChange)).toEqual([]);

  await page.getByRole('button', { name: 'Nowy seed' }).click();
  await expect.poll(async () => {
    const nextHash = await page.locator('.avatar-status strong').textContent();
    return (nextHash || '').trim();
  }, { timeout: 30000 }).not.toBe(secondHash);
  const thirdHash = ((await page.locator('.avatar-status strong').textContent()) || '').trim();
  const callsBeforeSecondPlaylistChange = apiCalls.length;
  await page.locator('.animation-select-field select').selectOption('scared');
  await expect.poll(async () => {
    const currentHash = await page.locator('.avatar-status strong').textContent();
    return (currentHash || '').trim();
  }, { timeout: 15000 }).toBe(thirdHash);
  expect(apiCalls.slice(callsBeforeSecondPlaylistChange)).toEqual([]);

  expect(messages).toEqual([]);
});
