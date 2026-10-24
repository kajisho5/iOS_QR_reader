export type Block =
  | { kind: "p"; text: string }
  | { kind: "list"; items: string[] }
  | { kind: "note"; text: string }
  | { kind: "link"; text: string; href: string };

export type LegalSection = { id: string; heading: string; blocks: Block[] };

export type LegalDoc = {
  title: string;
  description: string;
  enactedOn: string;
  updatedOn: string;
  lead: string;
  sections: LegalSection[];
};

export type FaqItem = { id: string; question: string; answer: Block[] };
