interface IconProps {
  className?: string;
}

/** Margarita con pétalos gruesos. El color de los pétalos viene de `text-*` (currentColor). */
export const DaisyPetalSVG = ({ className = 'w-6 h-6 text-white' }: IconProps) => (
  <svg className={`${className} filter drop-shadow-sm`} viewBox="0 0 100 100" fill="none">
    <g fill="currentColor">
      <ellipse cx="50" cy="18" rx="14" ry="22" />
      <ellipse cx="50" cy="82" rx="14" ry="22" />
      <ellipse cx="18" cy="50" rx="22" ry="14" />
      <ellipse cx="82" cy="50" rx="22" ry="14" />
      <ellipse cx="27" cy="27" rx="14" ry="22" transform="rotate(-45 27 27)" />
      <ellipse cx="73" cy="73" rx="14" ry="22" transform="rotate(-45 73 73)" />
      <ellipse cx="27" cy="73" rx="14" ry="22" transform="rotate(45 27 73)" />
      <ellipse cx="73" cy="27" rx="14" ry="22" transform="rotate(45 73 27)" />
    </g>
    <circle cx="50" cy="50" r="18" fill="#D97706" />
    <circle cx="50" cy="50" r="15" fill="#F59E0B" />
    <circle cx="50" cy="50" r="12" fill="#FBBF24" />
    <circle cx="46" cy="46" r="4" fill="#FEF3C7" opacity="0.8" />
  </svg>
);

export const SunflowerSVG = ({ className = 'w-6 h-6' }: IconProps) => (
  <svg className={`${className} filter drop-shadow-sm`} viewBox="0 0 100 100" fill="none">
    <g fill="#F59E0B">
      <ellipse cx="50" cy="16" rx="9" ry="20" />
      <ellipse cx="50" cy="84" rx="9" ry="20" />
      <ellipse cx="16" cy="50" rx="20" ry="9" />
      <ellipse cx="84" cy="50" rx="20" ry="9" />
      <ellipse cx="26" cy="26" rx="9" ry="20" transform="rotate(-45 26 26)" />
      <ellipse cx="74" cy="74" rx="9" ry="20" transform="rotate(-45 74 74)" />
      <ellipse cx="26" cy="74" rx="9" ry="20" transform="rotate(45 26 74)" />
      <ellipse cx="74" cy="26" rx="9" ry="20" transform="rotate(45 74 26)" />
    </g>
    <g fill="#FBBF24">
      <ellipse cx="50" cy="20" rx="7" ry="16" />
      <ellipse cx="50" cy="80" rx="7" ry="16" />
      <ellipse cx="20" cy="50" rx="16" ry="7" />
      <ellipse cx="80" cy="50" rx="16" ry="7" />
      <ellipse cx="29" cy="29" rx="7" ry="16" transform="rotate(-45 29 29)" />
      <ellipse cx="71" cy="71" rx="7" ry="16" transform="rotate(-45 71 71)" />
      <ellipse cx="29" cy="71" rx="7" ry="16" transform="rotate(45 29 71)" />
      <ellipse cx="71" cy="29" rx="7" ry="16" transform="rotate(45 71 29)" />
    </g>
    <circle cx="50" cy="50" r="22" fill="#451A03" />
    <circle cx="50" cy="50" r="19" fill="#78350F" />
    <circle cx="50" cy="50" r="16" stroke="#B45309" strokeDasharray="3 3" strokeWidth="2" fill="none" />
    <circle cx="45" cy="45" r="5" fill="#FDE68A" opacity="0.3" />
  </svg>
);
