import Image from 'next/image';
import { save } from './actions';
export default function Page() {
  return (
    <main>
      <h1>repro</h1>
      <Image src="/logo.png" alt="logo" width={32} height={32} />
      <form action={save}><input name="q" /><button>Save</button></form>
    </main>
  );
}
