#!/usr/bin/env node

/**
 * Gerador Universal de PDF para Sistema spec-kit
 *
 * Converte Markdown para PDF com renderização automática de diagramas Mermaid.
 *
 * Características:
 * - Extrai e renderiza diagramas Mermaid como PNG
 * - Usa md-to-pdf para conversão final
 * - Mantém markdown como fonte única
 * - Imagens versionáveis no Git
 *
 * Dependências:
 * - puppeteer (precisa instalar: npm install puppeteer)
 * - md-to-pdf (via npx, não precisa instalar)
 *
 * Uso:
 *   node scripts/node/md-to-pdf.js <arquivo.md>
 *   node scripts/node/md-to-pdf.js specs/001-feature/spec-stak.md
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

// ES modules compatibility
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Cores para output
const colors = {
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    red: '\x1b[31m',
    cyan: '\x1b[36m',
    reset: '\x1b[0m'
};

// Argumentos
const INPUT_FILE = process.argv[2];

if (!INPUT_FILE) {
    console.log(`${colors.yellow}Uso: node md-to-pdf.js <arquivo.md>${colors.reset}`);
    console.log('');
    console.log('Exemplos:');
    console.log('  node scripts/node/md-to-pdf.js specs/001-auth/spec.md');
    console.log('  node scripts/node/md-to-pdf.js specs/001-auth/spec-stak.md');
    process.exit(1);
}

if (!fs.existsSync(INPUT_FILE)) {
    console.error(`${colors.red}Arquivo não encontrado: ${INPUT_FILE}${colors.reset}`);
    process.exit(1);
}

// Paths
const OUTPUT_PDF = INPUT_FILE.replace('.md', '.pdf');
const IMAGES_DIR = path.join(path.dirname(INPUT_FILE), 'images');
const TEMP_MD = INPUT_FILE.replace('.md', '-temp.md');

// Template HTML para renderizar Mermaid via CDN
const MERMAID_HTML_TEMPLATE = `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
        mermaid.initialize({
            startOnLoad: true,
            theme: 'neutral',
            securityLevel: 'loose',
            fontSize: 14,
            flowchart: { htmlLabels: true, curve: 'basis' },
            sequence: { actorMargin: 50, mirrorActors: false },
            gantt: { titleTopMargin: 25, barHeight: 20 }
        });
    </script>
    <style>
        body { margin: 0; padding: 20px; background: white; }
        .mermaid { display: inline-block; }
    </style>
</head>
<body>
    <div class="mermaid">{{DIAGRAM}}</div>
</body>
</html>`;

/**
 * Extrai blocos Mermaid do markdown
 */
function extractMermaidBlocks(markdown) {
    const blocks = [];
    const regex = /```mermaid\n([\s\S]*?)```/g;
    let match;
    let index = 0;

    while ((match = regex.exec(markdown)) !== null) {
        blocks.push({
            index: index++,
            code: match[1].trim(),
            fullMatch: match[0],
            position: match.index
        });
    }

    return blocks;
}

/**
 * Gera imagens PNG dos diagramas Mermaid usando Puppeteer
 */
async function generateDiagramImages(blocks) {
    if (blocks.length === 0) {
        console.log(`${colors.cyan}Nenhum diagrama Mermaid encontrado${colors.reset}`);
        return;
    }

    // Criar diretório de imagens
    if (!fs.existsSync(IMAGES_DIR)) {
        fs.mkdirSync(IMAGES_DIR, { recursive: true });
    }

    console.log(`${colors.cyan}Renderizando ${blocks.length} diagrama(s) Mermaid...${colors.reset}`);

    // Importar puppeteer dinamicamente
    let puppeteer;
    try {
        puppeteer = await import('puppeteer');
    } catch (err) {
        console.error(`${colors.red}Puppeteer não instalado. Execute: npm install puppeteer${colors.reset}`);
        console.log(`${colors.yellow}Continuando sem renderização de diagramas...${colors.reset}`);
        return;
    }

    const browser = await puppeteer.default.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    for (const block of blocks) {
        const imagePath = path.join(IMAGES_DIR, `diagram-${block.index}.png`);

        try {
            const page = await browser.newPage();
            await page.setViewport({ width: 1200, height: 800 });

            const html = MERMAID_HTML_TEMPLATE.replace('{{DIAGRAM}}', block.code);
            await page.setContent(html, { waitUntil: 'networkidle0' });

            // Aguardar renderização do Mermaid
            await new Promise(resolve => setTimeout(resolve, 2000));

            const element = await page.$('.mermaid');
            if (element) {
                await element.screenshot({ path: imagePath, type: 'png' });
                console.log(`  ${colors.green}✓${colors.reset} diagram-${block.index}.png`);
            }

            await page.close();
            block.imagePath = `images/diagram-${block.index}.png`;
        } catch (err) {
            console.error(`  ${colors.red}✗${colors.reset} Erro no diagrama ${block.index}: ${err.message}`);
        }
    }

    await browser.close();
}

/**
 * Substitui blocos Mermaid por referências às imagens
 */
function replaceMermaidWithImages(markdown, blocks) {
    let result = markdown;

    // Substituir de trás para frente para manter posições corretas
    for (let i = blocks.length - 1; i >= 0; i--) {
        const block = blocks[i];
        if (block.imagePath) {
            const imageRef = `\n![Diagrama ${block.index + 1}](${block.imagePath})\n`;
            result = result.substring(0, block.position) +
                     imageRef +
                     result.substring(block.position + block.fullMatch.length);
        }
    }

    return result;
}

/**
 * Gera o PDF final usando md-to-pdf
 */
function generatePDFFromMarkdown(markdownFile, outputFile) {
    console.log(`${colors.cyan}Gerando PDF...${colors.reset}`);

    try {
        execSync(
            `npx md-to-pdf "${markdownFile}" --pdf-options '{"format": "A4", "margin": "20mm", "printBackground": true}'`,
            { stdio: 'inherit' }
        );

        // Renomear se necessário (md-to-pdf gera com mesmo nome)
        const generatedPdf = markdownFile.replace('.md', '.pdf');
        if (generatedPdf !== outputFile && fs.existsSync(generatedPdf)) {
            fs.renameSync(generatedPdf, outputFile);
        }

        return true;
    } catch (err) {
        console.error(`${colors.red}Erro ao gerar PDF: ${err.message}${colors.reset}`);
        return false;
    }
}

/**
 * Função principal
 */
async function main() {
    console.log(`${colors.green}📄 Gerando PDF: ${INPUT_FILE}${colors.reset}`);
    console.log('');

    // 1. Ler markdown original
    const markdown = fs.readFileSync(INPUT_FILE, 'utf-8');

    // 2. Extrair blocos Mermaid
    const mermaidBlocks = extractMermaidBlocks(markdown);

    // 3. Gerar imagens dos diagramas
    await generateDiagramImages(mermaidBlocks);

    // 4. Substituir blocos Mermaid por imagens
    let processedMarkdown = markdown;
    if (mermaidBlocks.some(b => b.imagePath)) {
        processedMarkdown = replaceMermaidWithImages(markdown, mermaidBlocks);

        // Salvar markdown temporário
        fs.writeFileSync(TEMP_MD, processedMarkdown);
    }

    // 5. Gerar PDF
    const markdownToConvert = mermaidBlocks.some(b => b.imagePath) ? TEMP_MD : INPUT_FILE;
    const success = generatePDFFromMarkdown(markdownToConvert, OUTPUT_PDF);

    // 6. Limpar arquivo temporário
    if (fs.existsSync(TEMP_MD)) {
        fs.unlinkSync(TEMP_MD);
    }

    // 7. Resultado
    console.log('');
    if (success && fs.existsSync(OUTPUT_PDF)) {
        console.log(`${colors.green}✓ PDF gerado com sucesso!${colors.reset}`);
        console.log(`  ${colors.cyan}Arquivo: ${OUTPUT_PDF}${colors.reset}`);
        if (mermaidBlocks.length > 0) {
            console.log(`  ${colors.cyan}Imagens: ${IMAGES_DIR}/${colors.reset}`);
        }
    } else {
        console.error(`${colors.red}✗ Falha ao gerar PDF${colors.reset}`);
        process.exit(1);
    }
}

// Executar
main().catch(err => {
    console.error(`${colors.red}Erro: ${err.message}${colors.reset}`);
    process.exit(1);
});
