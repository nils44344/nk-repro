'use server';
export async function save(formData: FormData) { console.log('saved', formData.get('q')); }
