import { useState } from "react";
export default function Page() {
  if (Math.random() > 1) { const [x] = useState(0); }
  return <img src="/a.png" />;
}
