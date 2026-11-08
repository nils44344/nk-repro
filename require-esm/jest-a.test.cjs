const chalk = require("chalk"); test("x", () => { expect(typeof (chalk.default ?? chalk).green).toBe("function"); });
