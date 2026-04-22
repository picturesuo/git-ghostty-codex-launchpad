# Codex shared session context

- Project name: EC50 St. Cloud Part 2
- Project directory: /Users/bensuo/Desktop/new-project
- Target file: BS_Ec50_Part2_StCloud_Data_Analysis.do
- Active task artifact ID: BS_Ec50_Part2_StCloud_Data_Analysis.do
- Session ID: a5196b41
- Session source of truth: this file

This session is for the named project only.
Wait for the user to give the next instruction before making changes.

## TASK ARTIFACT

1. Goal
- Define a reproducible, evidence-first EC 50 Part 2 data analysis workflow for St. Cloud, Minnesota in `BS_Ec50_Part2_StCloud_Data_Analysis.do`, with hypothesis selection driven by the actual Opportunity Atlas data before any memo drafting.

2. Scope
- In scope: one well-annotated analysis script in an EC 50 lab style; atlas-based exploration first; transparent St. Cloud tract identification; a small set of descriptive tables/figures; evidence-based hypothesis selection; one lockbox replication; and a short findings summary for later memo use.
- Out of scope: memo drafting, policy recommendations, causal overclaiming, complex model selection, machine learning, or unsupported claims about variables or results not present in the data.

3. Constraints
- Technical constraints: use the actual variables present in `atlas.dta` and `lockbox_atlas.dta`; keep the workflow reproducible; handle missing values explicitly; and use simple EC 50-appropriate descriptive methods, correlations, and at most a few clearly labeled descriptive regressions.
- Product constraints: do not write the memo yet; do not invent findings; keep conclusions at the level of a strong undergraduate empirical project; and use the lockbox only after the main hypothesis is chosen.
- Time or complexity constraints: prioritize a clean, interpretable workflow over exhaustiveness, with no more than 2-4 figures and 2-3 tables intended for later memo use.

4. Success Criteria
- SC1: `BS_Ec50_Part2_StCloud_Data_Analysis.do` is organized into the eight requested sections and uses clear EC 50-style headers plus short explanatory comments before each block.
- SC2: The script loads `atlas.dta`, inspects the available variables, filters Minnesota correctly, and creates a transparent St. Cloud geography workflow that distinguishes the broader Minnesota `St. Cloud` CZ from the narrower tract subset used for the main analysis.
- SC3: The script outputs a tract inclusion table with county and tract names, documents any ambiguous inclusion choices, and ranks St. Cloud tracts by pooled upward mobility.
- SC4: The script evaluates several plausible mechanisms using only available atlas covariates, reports simple descriptive comparisons and correlations, and handles thin race-specific cells carefully.
- SC5: The script contains an explicit "Evidence-based hypothesis selection" section that compares 2-4 candidate narratives and states one careful final hypothesis suitable for later memo development.
- SC6: The script uses `lockbox_atlas.dta` only after hypothesis selection, reproduces at least one central comparison for the same St. Cloud geography, and adds a concise findings summary plus completion checklist at the end.

5. Invariants
- INV1: Every numeric result, ranking, and graph must be generated from the actual data files in the workflow; no result may be inferred or fabricated outside the script output.
- INV2: The analysis must stay within EC 50 scope: descriptive, transparent, reproducible, and cautious about causal interpretation.
- INV3: The main geography decision must be explicit and reviewable, with any broader `St. Cloud` CZ context separated from the narrower community-of-interest subset.
- INV4: Lockbox analysis must remain out-of-sample validation rather than a second round of hypothesis fishing.

6. Failure Modes
- FM1: The analysis treats the full `St. Cloud` CZ as identical to St. Cloud proper and quietly mixes distant tracts into the main comparison set.
- FM2: The script overinterprets sparse race-specific estimates or missing cells as strong evidence.
- FM3: The workflow searches the lockbox for a better story after seeing the main sample results.
- FM4: The outputs become too broad or complicated for EC 50 and stop supporting a clear final hypothesis choice.

7. Risks / Open Questions
- R1: The broad Minnesota `St. Cloud` CZ contains 56 tracts across counties 009, 095, 141, and 145, so the main analysis needs a narrower and explicitly justified local subset to avoid geographic drift.
- R2: Race-specific mobility coverage appears thin in the atlas sample for this geography, especially for Hispanic outcomes and likely for Black outcomes, which limits how far heterogeneity analysis can go.
- R3: Only PDF versions of prior EC 50 labs are currently visible, so the lab-style formatting can be closely approximated but may still need adjustment if source notebooks or do-files are located later.
- Q1: Should the primary St. Cloud sample include only place names directly tied to the urban area (`St. Cloud`, `Waite Park`, `Sartell`, `Sauk Rapids`, and closely adjacent tracts), or also nearby small places such as `Saint Joseph`, `Saint Augusta`, and `Rice`?
- Q2: Should the deliverable be strictly a Stata `.do` file, or is an R notebook acceptable if later lab sources show a different house style?

8. Test Mapping
- SC1 -> Verify the target script contains the requested section order and readable EC 50-style comments or markdown-equivalent headings.
- SC2 -> Run the geography setup and confirm Minnesota filtering plus the broad-versus-core St. Cloud subsets are reproducible from observed `state`, `county`, `tract_name`, `cz`, and `czname` values.
- SC3 -> Check that the script prints an inclusion table with county and tract names and a ranked upward-mobility table for the chosen St. Cloud sample.
- SC4 -> Confirm each tested mechanism uses an existing atlas variable, reports missingness or thin-cell limits where relevant, and avoids unsupported causal language.
- SC5 -> Review the hypothesis selection block to ensure it compares multiple narratives and chooses one that matches the reported evidence.
- SC6 -> Verify the lockbox block runs only after the main selection block and reproduces at least one central comparison with a short interpretation plus final findings summary.


### Reusable Knowledge
- User-provided knowledge: none captured yet
- Durable project facts: none captured yet
- Retrieval path: search `docs/knowledge.md`, this shared context file, and nearby repo docs with `rg` before broader search.
- Ingestible sources in v1: direct user instructions, pasted facts, stable repo docs, and short summaries of resolved task decisions.

### Weak Spots / Coaching
- Weak spots: none recorded yet
- Coaching guidance: none recorded yet
- Learning loop: `CRITIC` should turn repeated or high-severity weak points into targeted coaching guidance that later roles can reuse.

9. Status
- State: ready for implementation
- Outstanding issues: Q1 and Q2 remain open, but they do not block drafting a conservative St. Cloud analysis workflow if the implementer makes the geography rule explicit and keeps the tool choice simple.
- Next action: implement `BS_Ec50_Part2_StCloud_Data_Analysis.do` to satisfy SC1-SC6, starting with data loading, Minnesota filtering, and the tract inclusion table.
