import type { MicrosoftCertification } from './data/microsoftCertifications';

export interface RenderOptions {
  name: string;
  certifications: MicrosoftCertification[];
  scale: number;
}

interface PosterSection {
  title: string;
  color: string;
  certifications: MicrosoftCertification[];
}

const POSTER_WIDTH = 1600;
const HEADER_HEIGHT = 200;
const POSTER_PADDING = 84;
const SECTION_GAP = 28;
const CARD_GAP = 20;
const FOOTER_HEIGHT = 110;

const SECTION_STYLES = {
  github: { title: 'GitHub', color: '#24292f' },
  workplace: { title: 'Microsoft 365', color: '#0078d4' },
  aiData: { title: 'AI + Data', color: '#008272' },
  infrastructure: { title: 'Azure Infrastructure', color: '#00a4ef' },
  security: { title: 'Security', color: '#b8860b' },
  businessApps: { title: 'Business Applications', color: '#742774' },
  office: { title: 'Office Specialist', color: '#d83b01' },
  other: { title: 'Other Certifications', color: '#5c6b73' },
} as const;

function slugify(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
}

function pickSectionKey(certification: MicrosoftCertification): keyof typeof SECTION_STYLES {
  const title = certification.title.toLowerCase();

  if (title.includes('github')) {
    return 'github';
  }

  if (certification.credentialTypes.includes('mos') || title.includes('office specialist')) {
    return 'office';
  }

  if (certification.credentialTypes.includes('business') || title.includes('dynamics 365') || title.includes('power platform')) {
    return 'businessApps';
  }

  if (title.includes('security') || title.includes('cybersecurity') || title.includes('identity and access') || title.includes('information security')) {
    return 'security';
  }

  if (title.includes('microsoft 365') || title.includes('teams administrator') || title.includes('endpoint administrator')) {
    return 'workplace';
  }

  if (title.includes('ai') || title.includes('fabric') || title.includes('power bi') || title.includes('data ')) {
    return 'aiData';
  }

  if (title.includes('azure') || title.includes('windows server')) {
    return 'infrastructure';
  }

  return 'other';
}

function groupCertifications(certifications: MicrosoftCertification[]): PosterSection[] {
  const buckets = new Map<keyof typeof SECTION_STYLES, MicrosoftCertification[]>();

  for (const certification of certifications) {
    const key = pickSectionKey(certification);
    const bucket = buckets.get(key);
    if (bucket) {
      bucket.push(certification);
    } else {
      buckets.set(key, [certification]);
    }
  }

  return (Object.keys(SECTION_STYLES) as Array<keyof typeof SECTION_STYLES>)
    .map((key) => ({
      title: SECTION_STYLES[key].title,
      color: SECTION_STYLES[key].color,
      certifications: (buckets.get(key) ?? []).sort((left, right) => left.title.localeCompare(right.title)),
    }))
    .filter((section) => section.certifications.length > 0);
}

function createScaledCanvas(width: number, height: number, scale: number): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(width * scale);
  canvas.height = Math.round(height * scale);

  const context = canvas.getContext('2d');
  if (!context) {
    throw new Error('Canvas rendering is not available in this browser.');
  }

  context.scale(scale, scale);
  return [canvas, context];
}

function wrapText(context: CanvasRenderingContext2D, text: string, maxWidth: number): string[] {
  const words = text.split(/\s+/);
  const lines: string[] = [];
  let currentLine = '';

  for (const word of words) {
    const nextLine = currentLine.length === 0 ? word : `${currentLine} ${word}`;
    if (context.measureText(nextLine).width <= maxWidth) {
      currentLine = nextLine;
      continue;
    }

    if (currentLine.length > 0) {
      lines.push(currentLine);
    }
    currentLine = word;
  }

  if (currentLine.length > 0) {
    lines.push(currentLine);
  }

  return lines;
}

function cardHeight(context: CanvasRenderingContext2D, title: string, width: number): number {
  const lines = wrapText(context, title, width - 54);
  return Math.max(88, 32 + lines.length * 28);
}

function sectionHeight(context: CanvasRenderingContext2D, section: PosterSection, width: number): number {
  const columnGap = CARD_GAP;
  const cardWidth = (width - columnGap) / 2;
  const rowHeights: number[] = [];

  for (let index = 0; index < section.certifications.length; index += 2) {
    const leftHeight = cardHeight(context, section.certifications[index].title, cardWidth);
    const rightHeight = index + 1 < section.certifications.length
      ? cardHeight(context, section.certifications[index + 1].title, cardWidth)
      : leftHeight;
    rowHeights.push(Math.max(leftHeight, rightHeight));
  }

  const cardsHeight = rowHeights.reduce((sum, value) => sum + value, 0) + Math.max(0, rowHeights.length - 1) * CARD_GAP;
  return 74 + 32 + cardsHeight + 30;
}

function totalPosterHeight(context: CanvasRenderingContext2D, sections: PosterSection[]): number {
  const contentWidth = POSTER_WIDTH - POSTER_PADDING * 2;
  const sectionHeights = sections.map((section) => sectionHeight(context, section, contentWidth));
  const sectionsHeight = sectionHeights.reduce((sum, value) => sum + value, 0) + Math.max(0, sectionHeights.length - 1) * SECTION_GAP;
  return HEADER_HEIGHT + POSTER_PADDING + sectionsHeight + FOOTER_HEIGHT;
}

function drawBackground(context: CanvasRenderingContext2D, width: number, height: number): void {
  // Draw the overall poster backdrop and subtle accent wash.
  const gradient = context.createLinearGradient(0, 0, width, height);
  gradient.addColorStop(0, '#f7f7f4');
  gradient.addColorStop(0.52, '#ecefe7');
  gradient.addColorStop(1, '#dde7e3');
  context.fillStyle = gradient;
  context.fillRect(0, 0, width, height);

  context.fillStyle = 'rgba(0, 164, 239, 0.10)';
  context.beginPath();
  context.arc(width - 120, 110, 220, 0, Math.PI * 2);
  context.fill();

  context.fillStyle = 'rgba(32, 32, 32, 0.06)';
  context.fillRect(0, 0, width, HEADER_HEIGHT);
}

function drawHeader(
  context: CanvasRenderingContext2D,
  width: number,
  selectedCount: number,
  name: string,
): void {
  // Render the top banner, title, tagline, and identity badge.
  context.fillStyle = '#1f1f1f';
  context.fillRect(0, 0, width, HEADER_HEIGHT);

  context.fillStyle = '#00a4ef';
  context.fillRect(0, 0, 24, HEADER_HEIGHT);
  context.fillStyle = '#008272';
  context.fillRect(24, 0, 24, HEADER_HEIGHT);
  context.fillStyle = '#d83b01';
  context.fillRect(48, 0, 24, HEADER_HEIGHT);

  context.fillStyle = '#f6f8fb';
  context.font = '700 80px "Segoe UI Display", "Segoe UI", sans-serif';
  context.fillText('I am Microsoft Certified', POSTER_PADDING, 120);

  context.fillStyle = 'rgba(246, 248, 251, 0.76)';
  context.font = '500 28px "Segoe UI Display", "Segoe UI", sans-serif';
  context.fillText('Check out my role-based certifications!', POSTER_PADDING, 160);

  const displayName = name.trim().length > 0 ? name.trim() : 'Your certification snapshot';
  const badgeWidth = 330;
  const badgeX = width - POSTER_PADDING - badgeWidth;
  const badgeY = 48;
  context.fillStyle = '#ffffff';
  context.beginPath();
  context.roundRect(badgeX, badgeY, badgeWidth, 118, 26);
  context.fill();

  context.fillStyle = '#1f1f1f';
  context.font = '700 30px "Segoe UI Display", "Segoe UI", sans-serif';
  context.fillText(displayName, badgeX + 24, badgeY + 54, badgeWidth - 48);
  context.font = '600 20px "Segoe UI Display", "Segoe UI", sans-serif';
  context.fillText(`${selectedCount} earned certification${selectedCount === 1 ? '' : 's'}`, badgeX + 24, badgeY + 90, badgeWidth - 48);
}

function drawSection(
  context: CanvasRenderingContext2D,
  section: PosterSection,
  x: number,
  y: number,
  width: number,
): number {
  // Render one certification category block and its certification cards.
  const sectionHeightValue = sectionHeight(context, section, width);

  context.fillStyle = 'rgba(255, 255, 255, 0.80)';
  context.strokeStyle = 'rgba(31, 31, 31, 0.08)';
  context.lineWidth = 1;
  context.beginPath();
  context.roundRect(x, y, width, sectionHeightValue, 30);
  context.fill();
  context.stroke();

  context.fillStyle = section.color;
  context.beginPath();
  context.roundRect(x, y, width, 74, 30);
  context.fill();
  context.fillRect(x, y + 38, width, 36);

  context.fillStyle = '#ffffff';
  context.font = '700 34px "Segoe UI Display", "Segoe UI", sans-serif';
  context.fillText(section.title, x + 26, y + 47);

  const cardWidth = (width - CARD_GAP - 52) / 2;
  let currentY = y + 106;

  for (let index = 0; index < section.certifications.length; index += 2) {
    const row = section.certifications.slice(index, index + 2);
    const heights = row.map((certification) => cardHeight(context, certification.title, cardWidth));
    const rowHeight = Math.max(...heights);

    row.forEach((certification, columnIndex) => {
      const cardX = x + 26 + columnIndex * (cardWidth + CARD_GAP);
      const lines = wrapText(context, certification.title, cardWidth - 54);

      context.fillStyle = 'rgba(255, 255, 255, 0.96)';
      context.beginPath();
      context.roundRect(cardX, currentY, cardWidth, rowHeight, 22);
      context.fill();

      context.strokeStyle = section.color;
      context.lineWidth = 2;
      context.stroke();

      context.fillStyle = section.color;
      context.beginPath();
      context.arc(cardX + 20, currentY + 45, 7, 0, Math.PI * 2);
      context.fill();

      context.font = '600 21px "Segoe UI Display", "Segoe UI", sans-serif';
      context.fillStyle = '#1f1f1f';
      lines.forEach((line, lineIndex) => {
        context.fillText(line, cardX + 36, currentY + 50 + lineIndex * 27, cardWidth);
      });
    });

    currentY += rowHeight + CARD_GAP;
  }

  return sectionHeightValue;
}

function drawFooter(context: CanvasRenderingContext2D, width: number, height: number): void {
  // Render the closing banner with the call to action and attribution.
  const footerY = height - FOOTER_HEIGHT;
  context.fillStyle = '#1f1f1f';
  context.fillRect(0, footerY, width, FOOTER_HEIGHT);

  context.fillStyle = '#f6f8fb';
  context.font = '600 22px "Segoe UI Display", "Segoe UI", sans-serif';
  context.fillText('Find your next Microsoft Certification at aka.ms/certposter', POSTER_PADDING, footerY + 44);
  context.fillStyle = 'rgba(246, 248, 251, 0.72)';
  context.font = '500 18px "Segoe UI Display", "Segoe UI", sans-serif';
  context.fillText('built by @miguelarcilla and GitHub Copilot', POSTER_PADDING, footerY + 76);
}
export async function renderPosterImage(options: RenderOptions): Promise<HTMLCanvasElement> {
  // Build the complete poster image from the selected certification list.
  const selectedCertifications = [...options.certifications].sort((left, right) => left.title.localeCompare(right.title));

  if (selectedCertifications.length === 0) {
    throw new Error('Select at least one certification before generating the image.');
  }

  const measureCanvas = document.createElement('canvas');
  const measureContext = measureCanvas.getContext('2d');
  if (!measureContext) {
    throw new Error('Canvas rendering is not available in this browser.');
  }

  measureContext.font = '600 21px "Segoe UI Display", "Segoe UI", sans-serif';
  const sections = groupCertifications(selectedCertifications);
  const height = totalPosterHeight(measureContext, sections);
  const [canvas, context] = createScaledCanvas(POSTER_WIDTH, height, options.scale);

  drawBackground(context, POSTER_WIDTH, height);
  drawHeader(context, POSTER_WIDTH, selectedCertifications.length, options.name);

  let currentY = HEADER_HEIGHT + POSTER_PADDING / 2;
  const contentWidth = POSTER_WIDTH - POSTER_PADDING * 2;
  for (const section of sections) {
    const renderedHeight = drawSection(context, section, POSTER_PADDING, currentY, contentWidth);
    currentY += renderedHeight + SECTION_GAP;
  }

  drawFooter(context, POSTER_WIDTH, height);
  return canvas;
}

export async function downloadPoster(canvas: HTMLCanvasElement, name: string): Promise<void> {
  const fileName = slugify(name) || 'microsoft-certification-poster';

  const blob = await new Promise<Blob | null>((resolve) => {
    canvas.toBlob((value) => resolve(value), 'image/png');
  });

  if (!blob) {
    throw new Error('The generated image could not be encoded.');
  }

  const href = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = href;
  link.download = `${fileName}.png`;
  link.click();
  URL.revokeObjectURL(href);
}