## Microsoft Certification Poster Generator

Single page app prototype for generating a certification-poster-style image that includes only the certifications a user has earned.

### What it does

- Uses a saved local reference file for the certification checklist.
- Generates a custom poster-style image instead of overlaying highlights on the official PDF poster.
- Lets the user enter a name or handle for the generated image.
- Exports a high-resolution PNG that includes only the selected certifications.

### Certification reference data

The checklist data is stored locally in `src/data/microsoftCertifications.ts`.

The current file was generated from the Microsoft Learn credentials content browser API:

- Endpoint: `https://learn.microsoft.com/api/contentbrowser/search/credentials`
- Filter: `credential_types = certification`
- Snapshot date: `2026-03-06`

### Run locally

```bash
npm install
npm run dev
```

### Microsoft Clarity

Clarity tracking is wired in as an optional client-side integration.

Set your Clarity project ID in a Vite environment variable:

```bash
VITE_CLARITY_PROJECT_ID=your-project-id
```

For local development, copy the value into `.env`.

For Azure Static Web Apps, add `VITE_CLARITY_PROJECT_ID` as an application setting so it is available during the build.

### Build

```bash
npm run build
```

### Notes

The generated image is custom-drawn in canvas to match the visual style of the certification poster while only including earned certifications. It no longer depends on loading or parsing the PDF poster.
