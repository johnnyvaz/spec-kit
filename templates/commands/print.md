---
description: Generate A4 print-optimized HTML combining business and technical specification overview
handoffs:
  - label: Clarify Specification
    agent: speckit.clarify
    prompt: Clarify specification requirements
  - label: View Stakeholder Doc
    agent: speckit.stak
    prompt: Generate or update spec-stak.md
  - label: Create Technical Plan
    agent: speckit.plan
    prompt: Create implementation plan
scripts:
  sh: scripts/bash/generate-print.sh --json
  ps: scripts/powershell/generate-print.ps1 -Json
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Purpose

Generate a print-optimized HTML document (A4 format) that combines:
- **Business content** from `spec-stak.md` (if available): Executive Summary, Success Metrics, ROI, Approval Status, Mermaid diagrams
- **Technical content** from `spec.md`: User Stories (P1 detailed, P2/P3 summarized), Key Entities, Success Criteria
- **Interactive elements**: Checkboxes for progress tracking, blank lines for manual notes, date fields

**Why this exists**: Working with AI involves extensive screen time that can cause visual stress. This command creates a physical A4 document for offline review, providing visual clarity and a comprehensive overview of what needs to be done.

## Execution Steps

### Step 1: Initialize Context

Run `{SCRIPT}` once from repository root and parse the JSON output to get:

- `FEATURE_SPEC`: Path to spec.md (input source - technical specification)
- `SPEC_STAK`: Path to spec-stak.md (optional input for business content)
- `PRINT_OUTPUT`: Path to spec-print.html (output target)
- `FEATURE_DIR`: Feature directory path
- `BRANCH`: Current feature branch name
- `STAK_EXISTS`: "true" if spec-stak.md available, "false" otherwise
- `HAS_GIT`: "true" if git repository, "false" otherwise

**Script execution notes**:
- The script validates that spec.md exists (prerequisite)
- spec-stak.md is optional (enhances output with business content)
- For single quotes in args like "I'm Groot", use escape syntax: `'I'\''m Groot'` (or double-quote if possible: `"I'm Groot"`)

### Step 2: Load Source Content

Read the following files to gather all necessary information:

1. **`FEATURE_SPEC` (spec.md)** - Always required. Extract:
   - Feature name and metadata (branch, date, status)
   - User Scenarios & Testing section (all user stories with priorities P1/P2/P3)
   - Requirements section (all FR-XXX functional requirements)
   - Success Criteria section (all SC-XXX measurable outcomes)
   - Edge Cases section
   - Key Entities section (data model concepts)
   - Assumptions section (if present)

2. **`SPEC_STAK` (if STAK_EXISTS == "true")** - Optional. Extract:
   - Executive Summary section
   - Business Case → Success Metrics table
   - Business Case → ROI section
   - Approval & Governance → Approval Status table
   - Decision Framework → Open Questions section
   - All Mermaid diagrams (User Journey, Architecture, ERD, Timeline, Flowcharts)

3. **`/memory/constitution.md` (if exists)** - Optional reference:
   - Project principles (for context in notes section)

### Step 3: Extract Business Content (if spec-stak.md exists)

If `STAK_EXISTS == "true"`, extract the following from spec-stak.md:

**Executive Summary**:
- Problem statement
- Solution overview
- Key value proposition

**Success Metrics** (from Business Case section):
- Table with columns: Metric | Target | Measurement Method
- Extract all rows

**ROI Information**:
- Expected revenue impact
- Cost savings
- Implementation investment

**Approval Status**:
- Table with columns: Role | Name | Status | Date | Comments
- Extract current approval state

**Mermaid Diagrams**:
- Store complete Mermaid code blocks for:
  - User Journey (sequence diagram)
  - High-Level Architecture (graph)
  - Entity Relationship Diagram
  - Implementation Timeline (Gantt chart)
  - Decision Flowchart
- Keep diagram code as-is for rendering

### Step 4: Extract Technical Content (from spec.md)

Extract the following from spec.md:

**User Stories**:
- Parse all user stories from "User Scenarios & Testing" section
- For each story, extract:
  - Priority (P1, P2, or P3)
  - Story title/description
  - Acceptance scenarios (for P1 only - detailed)
  - Independent test description (if present)
- **Content strategy**:
  - P1 stories: Full description + all acceptance scenarios (max 3 scenarios per story to fit A4)
  - P2 stories: Title only + priority badge
  - P3 stories: Title only + priority badge

**Key Entities**:
- Extract all entities from "Key Entities" section
- For each entity: Name + brief description
- **Limit**: If more than 15 entities, show top 10 most critical + count of omitted entities

**Success Criteria**:
- Extract all SC-XXX items from "Success Criteria" section
- Format: ID + description
- Will be displayed with checkboxes for tracking

**Clarification Items**:
- Search entire spec.md for `[NEEDS CLARIFICATION]` markers
- Extract the question/topic that needs clarification
- Include section/context where it appears

**Technical Decisions** (from spec-stak.md if exists):
- Extract items from "Decision Framework → Open Questions" section
- These are decisions that need team discussion
- Include assumptions if documented

### Step 5: Build HTML Structure

Create the HTML document with this structure:

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>[FEATURE_NAME] - Visão Completa para Impressão</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
        mermaid.initialize({
            startOnLoad: true,
            theme: 'neutral',
            securityLevel: 'loose'
        });
    </script>
    <style>
        /* CSS will be embedded here in Step 6 */
    </style>
</head>
<body>
    <!-- Content will be populated in Steps 7-9 -->
</body>
</html>
```

**Feature name extraction**:
- Use branch name (BRANCH field) or feature directory name
- Format: Convert "NNN-feature-name" → "Feature Name"

### Step 6: Generate CSS Framework

Embed the following CSS in the `<style>` section:

```css
/* Page setup for A4 printing */
@page {
    size: A4;
    margin: 15mm;
}

/* Global resets and print optimization */
* {
    color: #333 !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
    box-sizing: border-box;
}

html, body {
    height: 100%;
    margin: 0;
    padding: 0;
}

body {
    font-family: Arial, sans-serif;
    font-size: 7pt;
    color: #333;
    line-height: 1.3;
    padding: 10px;
}

/* Typography */
h1 {
    font-size: 10pt;
    border-bottom: 1px solid #666;
    padding-bottom: 3px;
    margin: 0 0 5px 0;
}

h2 {
    font-size: 8pt;
    margin: 5px 0 3px 0;
    background: #f0f0f0;
    padding: 2px 4px;
}

h3 {
    font-size: 7pt;
    margin: 3px 0 2px 0;
    font-weight: bold;
}

/* Layout - Three columns */
.cols {
    display: flex;
    gap: 8px;
    margin-top: 5px;
}

.col {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 5px;
}

/* Section color coding */
.business {
    background: #e3f2fd !important;
    padding: 5px;
    border-radius: 3px;
}

.technical {
    background: #fff9e6 !important;
    padding: 5px;
    border-radius: 3px;
}

.interactive {
    background: #e8f5e9 !important;
    padding: 5px;
    border-radius: 3px;
}

/* Tables */
table {
    width: 100%;
    border-collapse: collapse;
    font-size: 6pt;
    margin: 3px 0;
}

th, td {
    border: 0.5px solid #666;
    padding: 2px 3px;
    text-align: left;
    vertical-align: top;
}

th {
    background: #f0f0f0;
    font-weight: bold;
}

/* Interactive elements */
.checkbox {
    display: inline-block;
    width: 8px;
    height: 8px;
    border: 0.5px solid #666;
    margin-right: 3px;
    vertical-align: middle;
}

.item {
    display: flex;
    align-items: flex-start;
    gap: 3px;
    min-height: 14px;
    margin: 2px 0;
}

.item-text {
    flex: 1;
    border-bottom: 0.5px solid #ccc;
    min-height: 12px;
    padding: 0 2px;
}

.linha {
    border-bottom: 0.5px solid #ccc;
    min-height: 12px;
    margin: 2px 0;
}

/* Priority badges */
.priority {
    display: inline-block;
    padding: 1px 4px;
    border-radius: 2px;
    font-size: 6pt;
    font-weight: bold;
    margin-right: 3px;
}

.priority-p1 {
    background: #ffcdd2;
    color: #c62828 !important;
}

.priority-p2 {
    background: #fff9c4;
    color: #f57f17 !important;
}

.priority-p3 {
    background: #c8e6c9;
    color: #2e7d32 !important;
}

/* Mermaid diagrams */
.mermaid {
    max-width: 100%;
    overflow: hidden;
    margin: 5px 0;
}

.mermaid svg {
    max-width: 100%;
    height: auto;
}

/* Print optimizations */
@media print {
    .page-break {
        page-break-before: always;
    }

    table {
        page-break-inside: avoid;
    }

    section {
        page-break-inside: avoid;
    }
}

/* Footer */
.footer {
    margin-top: 10px;
    text-align: center;
    font-size: 5pt;
    color: #999 !important;
    border-top: 0.5px solid #ccc;
    padding-top: 3px;
}

/* Notice box */
.notice {
    background: #fff3cd;
    border: 1px solid #ffc107;
    padding: 5px;
    margin: 5px 0;
    font-size: 6pt;
    border-radius: 3px;
}
```

### Step 7: Populate Business Section (if spec-stak.md exists)

If `STAK_EXISTS == "true"`, create Column 1 (Business) with:

```html
<div class="col">
    <section class="business">
        <h2>VISÃO DE NEGÓCIO</h2>

        <h3>Executive Summary</h3>
        <p>[Insert Executive Summary content from spec-stak.md]</p>

        <h3>Success Metrics</h3>
        <table>
            <tr>
                <th>Métrica</th>
                <th>Meta</th>
                <th>Medição</th>
            </tr>
            [Insert rows from Success Metrics table]
        </table>

        <h3>ROI</h3>
        <p>[Insert ROI information]</p>

        <h3>Approval Status</h3>
        <table>
            <tr>
                <th>Papel</th>
                <th>Nome</th>
                <th>Status</th>
                <th>Data</th>
            </tr>
            [Insert rows from Approval Status table]
        </table>
    </section>

    <section class="business">
        <h2>DIAGRAMAS</h2>
        [For each Mermaid diagram found:]
        <h3>[Diagram Title]</h3>
        <div class="mermaid">
[Diagram code here]
        </div>
    </section>
</div>
```

If `STAK_EXISTS == "false"`, show notice instead:

```html
<div class="col">
    <div class="notice">
        <strong>Visão de Negócio Indisponível</strong><br>
        Execute <code>/stak</code> para gerar spec-stak.md com Executive Summary, métricas e diagramas.
    </div>
</div>
```

### Step 8: Populate Technical Section

Create Column 2 (Technical) with:

```html
<div class="col">
    <section class="technical">
        <h2>USER STORIES</h2>

        <h3>Prioridade 1 (Críticas)</h3>
        [For each P1 story:]
        <div style="margin-bottom: 5px;">
            <div>
                <span class="priority priority-p1">P1</span>
                <strong>[Story title]</strong>
            </div>
            <div style="font-size: 6pt; margin-left: 15px;">
                [Story description]
            </div>
            <div style="font-size: 6pt; margin-left: 15px; margin-top: 2px;">
                <em>Cenários:</em>
                <ul style="margin: 2px 0; padding-left: 15px;">
                    [List acceptance scenarios - max 3]
                    [If more than 3: add "... (ver spec.md completo)"]
                </ul>
            </div>
        </div>

        <h3>Prioridade 2 & 3</h3>
        <ul style="font-size: 6pt; margin: 2px 0; padding-left: 15px;">
            [For each P2/P3 story:]
            <li>
                <span class="priority priority-p2">P2</span> [Story title only]
            </li>
        </ul>
    </section>

    <section class="technical">
        <h2>KEY ENTITIES</h2>
        <table>
            <tr>
                <th>Entidade</th>
                <th>Descrição</th>
            </tr>
            [For each entity (max 10):]
            <tr>
                <td><strong>[Entity name]</strong></td>
                <td>[Brief description]</td>
            </tr>
        </table>
        [If entities > 10:]
        <p style="font-size: 5pt; font-style: italic;">
            + [X] entidades adicionais omitidas (ver spec.md)
        </p>
    </section>

    <section class="technical">
        <h2>SUCCESS CRITERIA</h2>
        [For each SC-XXX:]
        <div class="item">
            <span class="checkbox"></span>
            <div style="flex: 1;">
                <strong>[SC-XXX]:</strong> [Description]
            </div>
        </div>
    </section>
</div>
```

### Step 9: Add Interactive Elements

Create Column 3 (Interactive) with:

```html
<div class="col">
    <section class="interactive">
        <h2>CHECKLIST DE PROGRESSO</h2>

        <h3>Datas</h3>
        <div class="item">
            <strong>Início:</strong>
            <div class="item-text"></div>
        </div>
        <div class="item">
            <strong>Entrega:</strong>
            <div class="item-text"></div>
        </div>

        <h3>Status de Implementação</h3>
        [Create 8 checkbox items:]
        <div class="item">
            <span class="checkbox"></span>
            <div class="item-text"></div>
        </div>
    </section>

    <section class="interactive">
        <h2>ITENS A CLARIFICAR</h2>
        [If clarification items found in spec.md:]
        <div style="font-size: 6pt; margin-bottom: 3px;">
            [For each [NEEDS CLARIFICATION] item:]
            <div class="item">
                <span class="checkbox"></span>
                <div style="flex: 1;">
                    <strong>[Section]:</strong> [Clarification question/topic]
                </div>
            </div>
        </div>
        [If no clarification items:]
        <p style="font-size: 6pt; font-style: italic;">Nenhum item pendente de clarificação</p>
    </section>

    <section class="interactive">
        <h2>DECISÕES TÉCNICAS</h2>
        <h3>Para Discutir com Equipe</h3>
        [If "Open Questions" found in spec-stak.md:]
        <div style="font-size: 6pt; margin-bottom: 3px;">
            [For each open question:]
            <div class="item">
                <span class="checkbox"></span>
                <div style="flex: 1;">[Question text]</div>
            </div>
        </div>
        [If no open questions, create blank items:]
        <div class="item">
            <span class="checkbox"></span>
            <div class="item-text"></div>
        </div>
        [Repeat 4 more times for manual entry]
    </section>

    <section class="interactive">
        <h2>NOTAS DE IMPLEMENTAÇÃO</h2>
        <h3>Decisões Tomadas</h3>
        [Create 4 blank lines:]
        <div class="linha"></div>

        <h3>Bloqueadores / Riscos</h3>
        [Create 4 blank lines:]
        <div class="linha"></div>

        <h3>Próximos Passos</h3>
        [Create 4 blank lines:]
        <div class="linha"></div>
    </section>

    <section class="interactive">
        <h2>REFERÊNCIAS</h2>
        <div style="font-size: 6pt;">
            <strong>Feature:</strong> [BRANCH]<br>
            <strong>Spec:</strong> spec.md<br>
            <strong>Stak:</strong> spec-stak.md [if exists]<br>
            <strong>Plan:</strong> plan.md [if exists]
        </div>
    </section>
</div>
```

### Step 10: Handle Mermaid Diagrams

For each Mermaid diagram extracted in Step 3:

1. **Wrap in proper div**:
```html
<div class="mermaid">
[Exact Mermaid code from spec-stak.md]
</div>
```

2. **Diagram types to look for**:
   - `sequenceDiagram` - User Journey
   - `graph TD` or `graph LR` - Architecture/Flowcharts
   - `erDiagram` - Entity Relationships
   - `gantt` - Implementation Timeline

3. **Fallback handling**:
   - If no diagrams found: Show placeholder `<p style="font-size: 6pt; font-style: italic;">[Nenhum diagrama disponível]</p>`
   - If Mermaid code is malformed: Browser will show error, but don't block HTML generation
   - CDN handles rendering client-side

### Step 11: Optimize for Print

1. **Add page header**:
```html
<body>
    <h1>[Feature Name] - Visão Completa para Impressão</h1>
    <div style="font-size: 6pt; margin-bottom: 8px;">
        <strong>Branch:</strong> [BRANCH] |
        <strong>Gerado:</strong> [Current date in DD/MM/YYYY format]
    </div>

    [Three-column layout here]
```

2. **Add page footer**:
```html
    <div class="footer">
        Gerado em [Current date and time] - spec-kit print command
    </div>
</body>
```

3. **Smart page breaks**:
   - If content is very long, add `<div class="page-break"></div>` between major sections
   - CSS already has `page-break-inside: avoid` for tables and sections

### Step 12: Handle Edge Cases

**Edge Case 1: spec-stak.md doesn't exist**
- Show notice box in Column 1 (already covered in Step 7)
- Continue with technical content only

**Edge Case 2: Very long P1 stories**
- Limit to 3 acceptance scenarios per story
- Add "... (ver spec.md completo)" if truncated

**Edge Case 3: Too many entities**
- Show top 10 only
- Add count: "+ [X] entidades adicionais omitidas"

**Edge Case 4: Missing sections in spec.md**
- User Stories: Show notice "Nenhuma user story definida"
- Entities: Show notice "Nenhuma entidade definida"
- Success Criteria: Show notice "Nenhum critério definido"

**Edge Case 5: HTML special characters**
- Escape: `<` → `&lt;`, `>` → `&gt;`, `&` → `&amp;`, `"` → `&quot;`
- Apply to all extracted content before embedding

**Edge Case 6: Very long feature names**
- Truncate to 60 characters in title
- Show full name in metadata section

### Step 13: Validate HTML

Before writing, validate:

1. **HTML structure**:
   - ✓ DOCTYPE present
   - ✓ `<html>`, `<head>`, `<body>` properly nested
   - ✓ All tags closed
   - ✓ UTF-8 charset specified

2. **CSS validity**:
   - ✓ No syntax errors in embedded CSS
   - ✓ @page rule properly formatted
   - ✓ All classes referenced in HTML are defined

3. **Content completeness**:
   - ✓ Feature name present
   - ✓ At least technical section populated
   - ✓ Footer with generation timestamp

4. **Mermaid setup**:
   - ✓ CDN script tag present
   - ✓ mermaid.initialize() called
   - ✓ Diagrams wrapped in `.mermaid` divs

### Step 14: Write Output

1. **Build complete HTML in memory** (don't write incrementally)

2. **Write atomically** to `PRINT_OUTPUT`:
   - Single write operation with full content
   - Prevents partial/corrupted files

3. **Report success**:
```
✓ Print-optimized HTML generated successfully!

Output: [PRINT_OUTPUT]

To view:
1. Open in browser: open [PRINT_OUTPUT]
2. Print: Ctrl+P (Cmd+P on Mac)
3. Settings: A4, landscape (opcional), cores habilitadas

Content included:
[✓] Technical specification (spec.md)
[✓/✗] Business content (spec-stak.md) - [available/not available]
[✓] Interactive elements (checkboxes, notes)
[✓] Mermaid diagrams - [X diagrams rendered / none available]
```

4. **Handoff suggestions**:
   - If spec-stak.md missing: "Run /stak to generate business content"
   - If plan.md missing: "Run /plan to create implementation plan"

## Operating Principles

1. **Graceful Degradation**: Work with minimal prerequisites (spec.md only)
2. **Visual Clarity**: Optimize typography and spacing for readability when printed
3. **Information Density**: Fit comprehensive overview on 1-2 A4 pages through smart prioritization
4. **Offline Utility**: Include interactive elements (checkboxes, blank lines) for manual use
5. **Atomic Operations**: Build complete HTML in memory before single write
6. **Error Tolerance**: Don't fail on missing optional content (spec-stak.md, diagrams)
7. **Print First**: CSS optimized specifically for physical printing, not screen viewing

## Content Prioritization Strategy

To fit on A4 paper:

- **P1 stories**: Full detail (up to 3 scenarios each)
- **P2/P3 stories**: Title only
- **Entities**: Top 10 most critical
- **Success Criteria**: All included (with checkboxes)
- **Diagrams**: All included (Mermaid renders compactly)
- **Interactive elements**: Generous space for manual notes

This creates a **scannable overview** that provides visual clarity while working offline, reducing screen fatigue during AI-assisted development.
