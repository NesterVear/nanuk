# Workflow preferences

- Makes his own git commits; the assistant should prepare changes but not commit on his behalf. Confidence: 0.95
- Wants documentation split into two tiers: internal/team docs vs public/user docs; internal docs must not be committed or pushed to GitHub. Confidence: 0.9
- Prefers shipping the ISO as a regular release and iterating on feedback rather than labeling it beta/pre-release. Confidence: 0.7
- Wants system updates delivered via `nanuk update` (pull repo + redeploy) without requiring users to reinstall packages or rebuild the ISO. Confidence: 0.75
- Wants the ISO to install the latest package versions at build/install time rather than pinned versions. Confidence: 0.7
- Wants internal documentation to include a short usage guide for each default program and an explanation of why that program was chosen over its alternatives. Confidence: 0.85
