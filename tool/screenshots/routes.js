// Per-shot routes + interactions for shoot.js. Array order defines the
// numbering (and therefore the store display order) of the output files.

// Focus the search bar (just under the app bar), type the query, and run it.
// The harness's stubbed SSE stream does the rest.
const runSearch = async (page, d) => {
  await page.mouse.click(d.vw / 2, 96);
  await page.waitForTimeout(500);
  await page.keyboard.type('cozy comfort food', { delay: 45 });
  await page.waitForTimeout(300);
  await page.keyboard.press('Enter');
};

module.exports = [
  {
    // Immersive hero: first result full-bleed with the agent's reason,
    // rating, refine bar, and the "Top picks ready" pill.
    name: 'search_picks',
    route: '/search',
    settle: 5500,
    post: 4500,
    actions: runSearch,
  },
  {
    // List view after the run: ★ Top picks section + everything found.
    name: 'search_list',
    route: '/search',
    params: 'view=list',
    settle: 5500,
    post: 4500,
    actions: runSearch,
  },
  {
    // Agent mid-run (the stub stream stalls while digging a collection):
    // narration strip + digging chips + live results.
    name: 'search_live',
    route: '/search',
    params: 'view=list',
    settle: 5500,
    post: 3500,
    actions: runSearch,
  },
  { name: 'home', route: '/home', settle: 6000 },
  { name: 'recipe_detail', route: '/recipe/r1', settle: 6000 },
  { name: 'preview', route: '/search/preview', settle: 6000 },
  { name: 'family', route: '/family', settle: 5000 },
  { name: 'import', route: '/import', settle: 5000 },
];
