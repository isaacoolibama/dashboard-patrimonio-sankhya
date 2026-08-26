# Dashboard de Patrimônio para Sankhya (TCIBEM)

Um dashboard executivo de patrimônio/ativo imobilizado, para rodar como
**componente HTML5** dentro do Sankhya — reúne numa visão única o que a
navegação padrão por grupo de produto não mostra de cara: KPIs, evolução
do valor ao longo do tempo, ranking por grupo, grade completa com filtro
e busca livre, e detalhe de cada bem. A ideia é tornar a consulta e a
identificação do patrimônio mais rápida e visual.

Funciona em **qualquer cliente Sankhya com banco Oracle ou MySQL** — a
consulta usa só tabelas padrão do módulo de Imobilizado (`TCIBEM`,
`TGFPRO`, `TGFGRU`, `TSIEMP`), sem nada específico de uma empresa. Também
não depende de CDN nem de fonte instalada: CSS, fonte e ícones ficam todos
embutidos no próprio arquivo, então o visual não quebra em ambientes
Sankhya sem saída pra internet ou com acesso a domínios externos bloqueado
(comum em instalações on-premise).

**Não tem SQL Server** — só Oracle e MySQL. Se seu Sankhya rodar em SQL
Server, esse projeto não serve como está.

## Qual versão baixar

O projeto existe em duas versões, com a consulta escrita na sintaxe SQL de
cada banco (o resto — tela, filtros, exportação — é idêntico):

| Versão | Pasta no repositório | Banco |
|---|---|---|
| Oracle | raiz do repositório (`patrimonio.jsp`, `dados_patrimonio.jsp`) | Oracle |
| MySQL | [`mysql/`](mysql/) (`mysql/patrimonio.jsp`, `mysql/dados_patrimonio.jsp`) | MySQL |

Baixe o `.zip` da versão certa pro banco do seu Sankhya na aba
[Releases](../../releases).

## Veja funcionando antes de instalar

Abra [`demo.html`](demo.html) direto no navegador (não precisa de servidor,
Sankhya ou banco de dados) — ele gera bens fictícios na hora e mostra a
tela **exatamente como ela roda dentro do Sankhya**, só que sem dado real
nenhum. Bom para conhecer a tela antes de instalar, ou pra gravar uma
demonstração.

## Instalação

| Arquivo | Papel |
|---|---|
| `patrimonio.jsp` | dashboard Oracle (entryPoint do componente HTML5) — CSS **embutido** em `<style>` no `<head>` |
| `dados_patrimonio.jsp` | consulta pesada Oracle (`<snk:query>`), buscada via XHR depois que a casca já carregou |
| `index.html` | redireciona para `patrimonio.jsp` |
| `css/patrimonioCSS.css` | cópia do CSS só pra facilitar leitura/edição (o que vale de verdade é o `<style>` embutido no `patrimonio.jsp`) |
| `mysql/` | mesma tela e mesmo `index.html`, com a consulta em sintaxe MySQL — ver [Qual versão baixar](#qual-versão-baixar) |
| `demo.html` | prévia estática com dados fictícios, roda em qualquer navegador (serve pras duas versões) |
| `dashboard-patrimonio-sankhya.zip` | pacote pronto **Oracle** — baixe na aba [Releases](../../releases) |
| `dashboard-patrimonio-sankhya-mysql.zip` | pacote pronto **MySQL** — baixe na aba [Releases](../../releases) |

### Passo a passo

1. Baixe o `.zip` da versão certa pro banco do seu Sankhya (Oracle ou
   MySQL) na aba [Releases](../../releases) deste repositório.
2. No Sankhya, abra o
   [Construtor de Componentes de BI](https://ajuda.sankhya.com.br/hc/pt-br/articles/360044605354-Construtor-de-Componentes-de-BI),
   crie um componente do tipo **HTML5** e suba o zip baixado no passo 1.
3. Abra o
   [Construtor de Dashboard](https://ajuda.sankhya.com.br/hc/pt-br/articles/360044605574-Construtor-de-Dashboards),
   adicione um novo item, pesquise o componente de BI criado no passo 2 e
   monte um lançador pra ele.
4. Em **Acessos**, libere a tela pros usuários que devem visualizá-la.

### Montando o zip você mesmo (só se for editar o código)

O zip precisa ter uma **pasta raiz única com entradas de diretório reais**
(ex.: `patrimonio/`) — um zip "achatado" (arquivos direto na raiz) não
carrega no Construtor de Componentes de BI. Monte uma pasta `patrimonio/`
contendo `patrimonio.jsp` (com o CSS já embutido), `dados_patrimonio.jsp`
e `index.html` — da raiz do repositório pra versão Oracle, ou de
[`mysql/`](mysql/) pra versão MySQL.

* **Linux/macOS:** rode `zip -r dashboard-patrimonio-sankhya.zip patrimonio`
  **a partir de dentro** da pasta que contém `patrimonio/` (não liste os
  arquivos soltos no comando `zip` — isso não cria as entradas de
  diretório).
* **Windows:** clique com o botão direito na **pasta `patrimonio`**
  (a pasta em si, não os arquivos dentro dela) e escolha **Enviar para >
  Pasta compactada (zipada)**. Renomeie o `.zip` gerado se quiser. Também
  funciona pelo PowerShell, a partir de dentro da pasta que contém
  `patrimonio/`: `Compress-Archive -Path patrimonio -DestinationPath
  dashboard-patrimonio-sankhya.zip`.

## Personalizando a logo

Por padrão, a sidebar mostra uma logo genérica de exemplo (ícone + texto
"Sua Empresa"), em `patrimonio.jsp`, dentro de `<div class="pat-logo-box">`:

```html
<div class="pat-logo-generico">
  <svg class="pat-ico pat-logo-ico" aria-hidden="true"><use href="#i-bem"></use></svg>
  <span>Sua Empresa</span>
</div>
```

Duas formas simples de trocar pela logo da sua empresa:

* **Só texto** — edite o `<span>Sua Empresa</span>` pro nome da sua empresa.
  Zero configuração extra.
* **Imagem de verdade** — troque o bloco inteiro por uma `<img>` com a logo
  em base64 (mesma técnica usada no resto do projeto, já que `<link>`/URL
  externa não é confiável dentro do Sankhya):

  ```html
  <img class="pat-logo" alt="Sua Empresa" src="data:image/png;base64,...">
  ```

  Gere o base64 com (Linux/macOS): `base64 -w0 sua-logo.png` — cole o
  resultado no lugar de `...` acima. Ajuste `.pat-logo-box`/`.pat-logo` no
  CSS se o tamanho não ficar bom (procure por `pat-logo-box` no `<style>`).

A paleta de cores também é fácil de trocar: as variáveis `--pat-s1` (cor
primária) e `--pat-s2` (cor secundária) ficam no topo do CSS, dentro de
`.pat { ... }`.

## Como a consulta funciona

Consulta real, gerada em `dados_patrimonio.jsp` (as duas linhas de
`CODEMP`/`CODPROD` só entram quando o drill-down chega preenchido; sem
elas é só tirar as duas linhas). Versão **Oracle** (raiz do repositório):

```sql
SELECT * FROM (
  SELECT
    BEM.*,
    TO_CHAR(BEM.DTCOMPRA, 'YYYY-MM-DD')                      AS X_DTCOMPRA,
    TO_CHAR(BEM.DTBAIXA, 'YYYY-MM-DD')                       AS X_DTBAIXA,
    TO_CHAR(NVL(BEM.VLRAQUISICAO, 0), 'FM99999999999990.00') AS X_VLRAQUIS,
    TO_CHAR(BEM.CODBEM)                                      AS X_CODBEM,
    TO_CHAR(BEM.CODPROD)                                     AS X_CODPROD,
    TO_CHAR(BEM.CODEMP)                                      AS X_CODEMP,
    BEM.DESCRBEM                                             AS X_DESCRBEM,
    PRO.DESCRPROD                                            AS X_DESCRPROD,
    PRO.REFERENCIA                                           AS X_REFERENCIA,
    PRO.MARCA                                                AS X_MARCA,
    TO_CHAR(PRO.CODGRUPOPROD)                                AS X_CODGRUPO,
    NVL(GRU.DESCRGRUPOPROD, 'Sem grupo')                     AS X_GRUPO,
    NVL(EMP.NOMEFANTASIA, 'Empresa ' || BEM.CODEMP)          AS X_EMPRESA
    FROM TCIBEM BEM
    LEFT JOIN TGFPRO PRO ON PRO.CODPROD      = BEM.CODPROD
    LEFT JOIN TGFGRU GRU ON GRU.CODGRUPOPROD = PRO.CODGRUPOPROD
    LEFT JOIN TSIEMP EMP ON EMP.CODEMP       = BEM.CODEMP
   WHERE BEM.CODBEM IS NOT NULL
     AND TRIM(TO_CHAR(BEM.CODBEM)) IS NOT NULL
     AND UPPER(TRIM(TO_CHAR(BEM.CODBEM))) <> '<TODOS>'
     AND BEM.CODEMP = 1    -- só entra se o drill-down vier com empresa
     AND BEM.CODPROD = 293 -- só entra se o drill-down vier com produto
   ORDER BY BEM.CODBEM
) WHERE ROWNUM <= 20000
```

Versão **MySQL** ([`mysql/`](mysql/)) — mesmas colunas e o mesmo filtro,
só troca a sintaxe: `TO_CHAR` vira `CAST(... AS CHAR)`/`DATE_FORMAT`,
`NVL` vira `IFNULL`, `||` vira `CONCAT`, e o corte de linhas usa `LIMIT`
em vez do truque `ROWNUM` (que não existe no MySQL):

```sql
SELECT
  BEM.*,
  DATE_FORMAT(BEM.DTCOMPRA, '%Y-%m-%d')                    AS X_DTCOMPRA,
  DATE_FORMAT(BEM.DTBAIXA, '%Y-%m-%d')                     AS X_DTBAIXA,
  CAST(IFNULL(BEM.VLRAQUISICAO, 0) AS DECIMAL(18,2))       AS X_VLRAQUIS,
  CAST(BEM.CODBEM AS CHAR)                                 AS X_CODBEM,
  CAST(BEM.CODPROD AS CHAR)                                AS X_CODPROD,
  CAST(BEM.CODEMP AS CHAR)                                 AS X_CODEMP,
  BEM.DESCRBEM                                             AS X_DESCRBEM,
  PRO.DESCRPROD                                            AS X_DESCRPROD,
  PRO.REFERENCIA                                           AS X_REFERENCIA,
  PRO.MARCA                                                AS X_MARCA,
  CAST(PRO.CODGRUPOPROD AS CHAR)                           AS X_CODGRUPO,
  IFNULL(GRU.DESCRGRUPOPROD, 'Sem grupo')                  AS X_GRUPO,
  IFNULL(EMP.NOMEFANTASIA, CONCAT('Empresa ', BEM.CODEMP)) AS X_EMPRESA
  FROM TCIBEM BEM
  LEFT JOIN TGFPRO PRO ON PRO.CODPROD      = BEM.CODPROD
  LEFT JOIN TGFGRU GRU ON GRU.CODGRUPOPROD = PRO.CODGRUPOPROD
  LEFT JOIN TSIEMP EMP ON EMP.CODEMP       = BEM.CODEMP
 WHERE BEM.CODBEM IS NOT NULL
   AND TRIM(CAST(BEM.CODBEM AS CHAR)) IS NOT NULL
   AND UPPER(TRIM(CAST(BEM.CODBEM AS CHAR))) <> '<TODOS>'
   AND BEM.CODEMP = 1    -- só entra se o drill-down vier com empresa
   AND BEM.CODPROD = 293 -- só entra se o drill-down vier com produto
 ORDER BY BEM.CODBEM LIMIT 20000
```

* `BEM.*` traz **todas** as colunas da TCIBEM, inclusive campos
  customizados (`AD_CHASSI`, `AD_PLACA`, `AD_NUMSERIE`...). A tela lê as
  colunas dinamicamente — nada precisa ser cadastrado para um campo novo
  aparecer.
* Os apelidos `X_*` alimentam os indicadores e a busca livre.
* Filtro, ordenação, seleção de colunas e exportação rodam no navegador,
  sobre a base já carregada — sem ida ao servidor a cada clique.
* O corte de 20000 linhas (`ROWNUM`/`LIMIT`, conforme o banco) é uma
  proteção, não uma exigência do negócio — evita
  mudando a constante `LIMITE` no topo de `patrimonio.jsp`/
  `dados_patrimonio.jsp`.

## O que a tela oferece

* **Sidebar** — logo (ver "Personalizando a logo" acima), navegação (Visão
  geral / Todos os bens / Ativos / Baixados — a situação do filtro é
  definida só por aqui), busca livre e botão **Atualizar base**. Em telas
  menores vira um menu recolhível.
* **Visão geral** — carregada automaticamente na abertura: KPIs (valor de
  aquisição, bens ativos, em uso, baixados), gráfico "Evolução do
  patrimônio" (valor acumulado dos últimos 12 meses + volume de aquisições
  por mês, rotulado `Mmm/AA` pra não ambiguar a virada do ano), ranking de
  patrimônio por grupo e feed das últimas aquisições.
* **Grade tipo Excel** — clicar numa célula **seleciona** (arrastar marca
  um retângulo, Shift+clique estende, `Ctrl`/`Cmd`+`C` copia como TSV —
  cola direto no Excel/Sheets). Como a célula agora seleciona em vez de
  abrir o detalhe, cada linha tem um botão dedicado (ícone de olho, coluna
  Situação) pra abrir a gaveta de detalhe; duplo-clique na linha também
  abre.
  * **Colunas**: arrastar o cabeçalho reordena; arrastar a borda direita
    **redimensiona** (como no Excel); o funil ordena e filtra por valores
    (marcar/desmarcar, busca, A-Z/Z-A). Botão *Colunas* escolhe quais
    aparecem.
  * **Estado por usuário**: colunas visíveis, ordem, largura, filtros e
    ordenação ficam salvos no `localStorage` do navegador — persistem
    entre sessões e são "por usuário" na prática, já que cada um abre o
    Sankhya com o próprio perfil de navegador.
  * **Código do bem**: dois botões aparecem no hover da linha — copiar o
    código, e abrir a tela nativa **Movimentação de Bem**
    (`br.com.sankhya.mgeimob.movimentacaobem`) já filtrada por código do
    bem + código do produto (o script preenche o formulário nativo daquela
    tela e clica em Aplicar automaticamente).
  * *Colunas*, *Excel* e *CSV* ficam no cabeçalho da própria grade.
* **Detalhe do bem** — modal com todos os campos do registro, agrupados
  por seção (Identificação, Outras informações, Datas, Valores).
* **Consulta vinculada de produto** — campo de código e de descrição com
  sugestões (até 8), sem alterar a grade até selecionar. Modal de pesquisa
  ampliada busca por código, descrição ou referência em lotes de 50.
* **Filtros no cabeçalho da grade** — produto, período de compra, período
  de baixa e faixa de valor, com chips removíveis na sidebar.
* **Busca livre restrita a campos identificadores** — descrição, descrição
  abreviada, produto, referência, marca, grupo, empresa, nota fiscal,
  código do bem e qualquer campo customizado (`AD_*`). Ignora acentos;
  primeiro tenta a expressão completa, só cai pra termos separados se não
  achar nada exato.
* **Exportação** — Excel (`.xls`) e CSV (`;` + BOM) do resultado filtrado,
  com as colunas visíveis. Identificadores gravados como texto,
  preservando zeros à esquerda.
* **Controles nativos do Sankhya** — barra `VCompactBar` e botão
  `chartConfigButton`/`clear.cache.gif`, quando presentes, são localizados
  e ocultados (com `MutationObserver` cobrindo recriação).
* **Crédito do desenvolvedor** — no rodapé da sidebar tem uma marca d'água
  discreta com o nome de quem manteve este projeto; clicar abre um cartão
  com contato (GitHub, portfólio, WhatsApp). Fique à vontade pra editar ou
  remover (`#pat-dev-info-abrir`/`#pat-dev-info` em `patrimonio.jsp`), mas
  se puder deixar como está, ajuda outras pessoas da comunidade Sankhya a
  encontrar o projeto original.

## Padrões visuais

* **Paleta customizável** — cor primária (`--pat-s1`) e secundária
  (`--pat-s2`) em variáveis CSS, no topo do `<style>`. O padrão de fábrica
  é um verde institucional, mas trocar é só mudar essas duas variáveis.
* **Fonte Inter embutida em base64** (`@font-face`, `font-weight: 100 900`)
  — não depende de fonte instalada no cliente, renderiza igual em Linux e
  Windows.
* **Ícones Lucide** embutidos como sprite SVG dentro do próprio JSP, via
  `<use href="#i-...">`.
* Nada de CDN em lugar nenhum — muitos ambientes Sankhya bloqueiam ou não
  garantem acesso a domínios externos.

## Se algum campo não aparecer

O `SELECT` do `patrimonio.jsp` só usa colunas de TCIBEM/TGFPRO/TGFGRU/TSIEMP
já confirmadas (`CODPROD`, `DESCRPROD`, `REFERENCIA`, `MARCA`,
`CODGRUPOPROD`, `DESCRGRUPOPROD`, `CODEMP`, `NOMEFANTASIA`). Se quiser
trazer mais campos de produto (ex.: NCM), confira o nome exato da coluna
antes de editar o `SELECT` — um nome de coluna inexistente quebra a
consulta inteira e derruba o dashboard.

## Contribuindo

Issues e PRs são bem-vindos — é um projeto pequeno, feito pra tornar a
consulta e a identificação do patrimônio mais fácil e visual, e pode
ajudar outras empresas que usam o ERP.

## Licença

[MIT](LICENSE) — use, copie, modifique e reaproveite à vontade.
