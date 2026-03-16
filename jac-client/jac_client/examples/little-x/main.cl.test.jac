"""E2E tests for LittleX app."""

@ jactest.e2e test "login page loads with form" {
    await page.goto("/login");
    await expect(page.locator("text=Login to LittleX")).toBeVisible();
    await expect(page.locator("#username")).toBeVisible();
    await expect(page.locator("#password")).toBeVisible();
}

@ jactest.e2e test "login page has signup link" {
    await page.goto("/login");
    link = page.locator("text=Don't have an account? Sign up");
    await expect(link).toBeVisible();
}

@ jactest.e2e test "signup page loads with form" {
    await page.goto("/signup");
    await expect(page.locator("text=Sign Up for LittleX")).toBeVisible();
}

@ jactest.e2e test "unauthenticated user redirected to login from home" {
    await page.goto("/home");
    await expect(page).toHaveURL("/login");
}
