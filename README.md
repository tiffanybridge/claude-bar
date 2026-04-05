# ClaudeBar

A native macOS menu bar app that shows your Claude AI usage and estimated spend at a glance, so you know where your budget is going before it's gone.

---

## The Problem

I use Claude Code heavily across work and personal projects, but the tools Anthropic provides don't give individual contributors visibility into their own spend. My work usage is billed against a $200/month Enterprise budget, and the only way to check it was logging into a console I don't have full access to — after the fact. I had no way to see, in the moment, which projects were driving the most cost or whether I was on track to stay within budget.

## The Solution

ClaudeBar lives in your macOS menu bar and shows token usage and estimated cost in real time, broken down by project. You can set a monthly budget, see a live spend-vs-pace indicator, and separate work projects from personal ones — all without leaving your workflow. No API keys or admin access required for Claude Code users.

## How to Use

**Prerequisites:** macOS 13+, Xcode 14+ (to build from source)

**Setup:**

1. Clone the repo and open `Package.swift` in Xcode
2. Build and run (`Cmd+R`) — the Claude icon appears in your menu bar
3. Click the icon, then the gear to open Settings
4. Click "Add Account" and choose Claude Code
5. Optionally set a monthly spend limit and select which projects to include

**Example:** If you have three projects billed to a work Enterprise account and two personal side projects, create two accounts — one with just the work projects and a $200 budget, one with personal projects. Both appear in the same dropdown so you can monitor them side by side.

**Pricing calibration:** Enterprise accounts typically have volume discounts, so ClaudeBar's retail-price estimates may read high. Once you see your first actual bill, open account settings and enter a ratio — e.g., if ClaudeBar estimated $58 but you actually spent $34, enter 0.59. The estimate recalibrates immediately.

## How It Works

Claude Code stores a local log of every session on your machine. ClaudeBar reads those logs directly, totals up token usage by project and model, and applies Anthropic's published pricing to estimate cost — no network calls needed. It filters to the current calendar month and groups results by project so you can see which ones are driving spend. Account settings (names, budgets, project assignments) are stored locally; nothing leaves your machine.

## Tradeoffs

**Reading local files instead of calling an API.** Anthropic has a usage API, but it requires org-owner access that most individual contributors don't have. Reading local files means the tool works for anyone using Claude Code, with zero credentials required. The downside is that I'm depending on a file format that's undocumented and could change — I'd add a format version check before recommending this to a large team.

**Start with retail pricing, calibrate later.** I could have asked users for their exact per-token Enterprise rate during setup, but most people don't know their negotiated rates, and it would've created friction before anyone had seen the tool work. Starting with retail pricing and letting users adjust after their first bill is a lower-friction path to a useful number — and it surfaces the discount gap in a concrete way rather than asking users to do math upfront.

## What I Learned

**Observability is a product gap, not just a missing feature.** Anthropic's tooling doesn't surface per-project spend for individual users on Enterprise plans. That's not an oversight — it reflects an assumption that budget visibility is an admin-level concern. But the people who need to make real-time decisions about which account to use are the individual contributors, not the admins. Closing that gap was the whole point of building this.

**Scope decisions compound.** The original idea was simple: show a token count. But "token count" meant deciding what time window to use, which led to separating work and personal projects, which led to needing a budget field, which led to the pricing calibration problem. Every scoping decision opened another one. I got better at asking "what does the user actually do with this number?" before adding a feature — it filtered out a lot of complexity that would've made the tool harder to use.

**Building something you personally need is a fast feedback loop.** I found a real bug (subagent files inflating totals by ~2x) not through testing but because the numbers didn't match what I expected from my own usage. Using the tool daily meant I noticed things a test case wouldn't catch.

## Next Steps

1. **Status icon that reflects budget health.** The menu bar icon should change color — green/yellow/red — based on spend-vs-pace, so you get a signal without opening the dropdown. That's the whole point of a menu bar app.
2. **Daily spend sparkline.** A small chart showing spend per day this month would make it easy to spot a single expensive session versus steady background usage — two very different problems with different responses.
3. **Installable .dmg via GitHub Actions.** Right now, building requires Xcode. A CI pipeline that packages a signed .dmg on each release tag would let anyone install it, which is what it would take to share this with teammates.
