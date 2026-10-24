# Test strategy: <product>

## Test pyramid & tools
| Level | Tool | Runs on | Target |
|---|---|---|---|
| Unit | | every PR | ≥ 80% lines on business logic |
| Integration/API | | every PR | all endpoints |
| E2E | | every PR (smoke) / nightly (full) | critical paths |
| Performance | | before release | p95 < 300 ms |
| Accessibility | | every PR | WCAG 2.1 AA |
## Critical user paths (E2E)
## Test data & environments
## Quality gates (what blocks a merge / a release)
