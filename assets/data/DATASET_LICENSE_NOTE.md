# Dataset provenance & licensing

Source: https://github.com/hasaneyldrm/exercises-dataset

## Data (exercises.json) — MIT License

Names, categories, body parts, equipment, muscle groups/targets, and the
10-language instructions (en, es, it, tr, ru, zh, hi, pl, ko, fr) are released
under the **MIT License**. Freely reusable, including commercially, as long
as the copyright notice is retained (see `LICENSE` in the source repo).

## Media (images/ + videos/ GIFs) — © Gym visual, permission-based

The thumbnail images and animation GIFs are the property of **Gym visual**
(https://gymvisual.com/) and are redistributed in the source repo **with the
rights holder's permission**, under two conditions (per the repo's
`NOTICE.md`):

1. **Resolution capped at 180×180** — do not re-export at a higher
   resolution.
2. **Attribution required**: every exercise record carries an `attribution`
   field ("© Gym visual — https://gymvisual.com/") that must stay visible
   wherever the media is shown. This app surfaces it on the exercise detail
   screen and in Paramètres → Mentions légales.

This repo's permission is scoped to the source repository's own
redistribution — it is not a blanket license. For **personal, non-commercial
use** (this project's current scope) displaying the bundled media with the
attribution intact is consistent with the stated terms. Before any
commercial/production release, review Gym visual's own Terms & Conditions
(https://gymvisual.com/content/3-terms-and-conditions-of-use) and, if
needed, obtain a separate license directly from them — do not assume this
repo's permission extends to a redistributed commercial product.

## Swapping the data source later

`ExerciseRepository` (domain) + `LocalExerciseRepository`
(`lib/data/repositories/local_exercise_repository.dart`) fully encapsulate
this dataset's schema and media paths. Switching to a licensed/remote
provider means implementing `ExerciseRepository` again and rewiring
`exerciseRepositoryProvider` — no other layer references the dataset
directly.
