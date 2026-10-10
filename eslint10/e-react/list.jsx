export default function L({ items }) {
  return <ul>{items.map((i) => <li>{i}</li>)}</ul>;
}
