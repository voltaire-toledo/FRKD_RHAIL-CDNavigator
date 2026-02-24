# TODO — FRKD_RHAIL-CDNavigator

Tracks ongoing work across feature branches. Items marked `[x]` are complete.

## PR #1 — Documentation Review & Installation Gap Analysis

### Documentation Review
- [x] Review root `README.md` for accuracy, typos, and broken links
- [x] Review `solution/README.md` for accuracy and correctness
- [x] Review `azureresources/README.md` for completeness
- [x] Review `FAQ.md` for accuracy
- [x] Identify missing prerequisites and unclear installation steps

### Documentation Fixes (PR #1 scope)
- [x] Fix typos in `README.md` ("Reccomendation" → "Recommendation", "enviormental" → "environmental", double colon in CLI section)
- [x] Fix broken placeholder author links in `README.md`
- [x] Fix wrong `sourcecode` folder reference in `README.md` (actual folder is `solution`)
- [x] Fix wrong repo clone URL in `solution/README.md`
- [x] Fix wrong folder case `./Solution` → `./solution` in `solution/README.md`
- [x] Fix `ClaimsDenialNavigator.zip` reference in `solution/README.md` (no pre-built zip exists; solution must be packed from source)
- [x] Fix "Enviormental" typo in `solution/README.md`
- [x] Add `docs/INSTALLATION.md` consolidating all installation steps with prerequisites, required inputs, expected outputs, and troubleshooting

### Pending (future PRs)
- [ ] PR #2 — PowerShell prompting improvements (`AddResource.ps1`, `SetupSearchService_v1.ps1`)
  - [ ] Add interactive prompts for required user inputs (`tenant`, `sub`, `newRG`, `loc`) instead of hardcoded defaults
  - [ ] Add parameter validation and user-friendly error messages
  - [ ] Improve script output formatting and progress reporting
- [ ] PR #3 — Testing & validation procedures
  - [ ] Add smoke-test checklist for post-deployment Azure resource validation
  - [ ] Add Power Apps import verification steps
  - [ ] Document expected SharePoint configuration test
