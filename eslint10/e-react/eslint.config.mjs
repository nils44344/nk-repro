import { defineConfig } from "eslint/config";
import react from "eslint-plugin-react";

export default defineConfig([
  {
    files: ["**/*.jsx"],
    ...react.configs.flat.recommended,
    ...react.configs.flat["jsx-runtime"],
    rules: { ...react.configs.flat.recommended.rules, ...react.configs.flat["jsx-runtime"].rules },
    settings: { react: { version: "19.0" } },
  },
]);
