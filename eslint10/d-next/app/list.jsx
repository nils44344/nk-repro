export default function List({ items }) {
  return <ul>{items.map((i) => <li>{i}</li>)}</ul>;
}
