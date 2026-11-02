const DAISY_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" rx="22" fill="#12141d" />
  <g fill="#FFFFFF" transform="translate(12 12) scale(0.76)">
    <ellipse cx="50" cy="18" rx="8" ry="18" />
    <ellipse cx="50" cy="82" rx="8" ry="18" />
    <ellipse cx="18" cy="50" rx="18" ry="8" />
    <ellipse cx="82" cy="50" rx="18" ry="8" />
    <ellipse cx="27" cy="27" rx="8" ry="18" transform="rotate(-45 27 27)" />
    <ellipse cx="73" cy="73" rx="8" ry="18" transform="rotate(-45 73 73)" />
    <ellipse cx="27" cy="73" rx="8" ry="18" transform="rotate(45 27 73)" />
    <ellipse cx="73" cy="27" rx="8" ry="18" transform="rotate(45 73 27)" />
    <circle cx="50" cy="50" r="16" fill="#F59E0B" />
    <circle cx="50" cy="50" r="14" fill="#FBBF24" />
    <circle cx="47" cy="47" r="4" fill="#FDE68A" opacity="0.6" />
  </g>
</svg>`;

/** Inyecta el favicon de margarita como data URI (funciona también en file://). */
export const injectDaisyFavicon = (): void => {
  let link = document.querySelector<HTMLLinkElement>("link[rel*='icon']");
  if (!link) {
    link = document.createElement('link');
    link.rel = 'icon';
    document.head.appendChild(link);
  }
  link.type = 'image/svg+xml';
  link.href = `data:image/svg+xml,${encodeURIComponent(DAISY_SVG)}`;
};
