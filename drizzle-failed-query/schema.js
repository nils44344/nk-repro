import { pgTable, serial, text, uuid, integer } from 'drizzle-orm/pg-core';
export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
});
export const posts = pgTable('posts', {
  id: uuid('id').primaryKey().defaultRandom(),
  authorId: integer('author_id').notNull().references(() => users.id),
  title: text('title').notNull(),
});
