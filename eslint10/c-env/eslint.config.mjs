import js from "@eslint/js";
import globals from "globals";
import { defineConfig } from "eslint/config";

export default defineConfig([
  js.configs.recommended,
  { languageOptions: { globals: globals.node }, rules: { "no-unused-vars": "error" } },
]);
