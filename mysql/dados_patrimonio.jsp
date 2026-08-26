<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="UTF-8" isELIgnored="false"%>
<%@ page import="java.util.*" %>
<%@ taglib uri="http://java.sun.com/jstl/core_rt" prefix="c" %>
<%@ taglib prefix="snk" uri="/WEB-INF/tld/sankhyaUtil.tld" %>
<%!
	/* Extrai um parametro inteiro vindo do request - attribute (forward
	   direto de outra tela, se um dia esse caminho existir pra este JSP
	   especifico) OU parameter (querystring - o caminho de verdade hoje: ver
	   urlDados() em patrimonio.jsp, que repassa CODEMP/CODPROD recebidos no
	   forward inicial porque o attribute nao sobrevive a este XHR, que e' uma
	   requisicao HTTP nova). So digitos: a sanitizacao aqui e' a defesa
	   contra SQL injection, porque o valor vai como LITERAL na query abaixo
	   (nao como bind var - o mecanismo de resolucao de ":NOME" do
	   <snk:query> pra uma segunda requisicao XHR nao e' algo que da pra
	   confirmar sem uma instancia Sankhya real, entao evitamos depender
	   disso). */
	private String paramInteiro(javax.servlet.ServletRequest req, String nome) {
		Object v = req.getAttribute(nome);
		if (v == null) v = req.getParameter(nome);
		if (v == null) return "";
		String s = String.valueOf(v).trim();
		return s.matches("-?\\d+") ? s : "";
	}
%>
<%--
	=========================================================================
	Dados do Dashboard de Patrimonio - TCIBEM (versao MySQL)
	-------------------------------------------------------------------------
	Arquivo separado (chamado via XMLHttpRequest pelo patrimonio.jsp, depois
	que a casca da tela ja carregou) para que o spinner de "carregando" cubra
	a espera real da consulta no banco. Nao ha HTML de pagina aqui - so a
	tabela de dados brutos que o JS de patrimonio.jsp le e descarta.

	A consulta traz TODAS as colunas de TCIBEM (BEM.*) e cria apelidos X_*
	para os campos usados nos indicadores. As colunas sao lidas dinamicamente
	do resultado, entao campos customizados (AD_CHASSI, AD_PLACA, etc.)
	aparecem automaticamente na grade e na busca livre.

	Diferencas pra versao Oracle deste mesmo projeto: TO_CHAR(...) virou
	CAST(... AS CHAR) / DATE_FORMAT(...), NVL(...) virou IFNULL(...), a
	concatenacao com || virou CONCAT(...) e o corte de linhas via subquery +
	ROWNUM virou um LIMIT direto no final da query (MySQL nao tem ROWNUM).
	=========================================================================
--%>

<%
	int LIMITE = 20000;   // teto de registros carregados na tela (MySQL)
%>

<snk:query var="bens">
<%
	StringBuffer w = new StringBuffer(
		" WHERE BEM.CODBEM IS NOT NULL "
		+ " AND TRIM(CAST(BEM.CODBEM AS CHAR)) IS NOT NULL "
		+ " AND UPPER(TRIM(CAST(BEM.CODBEM AS CHAR))) <> '<TODOS>' "
	);

	// Parametros opcionais de drill-down de outra tela do Sankhya (CODEMP/
	// CODPROD, ver <level><args> em gadget_Patrimonio.xml e urlDados() em
	// patrimonio.jsp). Se nao vierem, a tela carrega o patrimonio inteiro e
	// todo o filtro acontece no navegador. Literais (ja' sanitizados como
	// so-digitos por paramInteiro), nao bind var - ver comentario dele acima.
	String pCodEmp = paramInteiro(request, "CODEMP");
	String pCodProd = paramInteiro(request, "CODPROD");
	if (!"".equals(pCodEmp))  w.append(" AND BEM.CODEMP = ").append(pCodEmp).append(" ");
	if (!"".equals(pCodProd)) w.append(" AND BEM.CODPROD = ").append(pCodProd).append(" ");

	// BEM.* traz todas as colunas da TCIBEM (inclusive campos customizados
	// AD_*). Os apelidos X_* padronizam o que os indicadores usam.
	String cols =
		  " BEM.*, "
		+ " DATE_FORMAT(BEM.DTCOMPRA, '%Y-%m-%d')                    AS X_DTCOMPRA, "
		+ " DATE_FORMAT(BEM.DTBAIXA, '%Y-%m-%d')                     AS X_DTBAIXA, "
		+ " CAST(IFNULL(BEM.VLRAQUISICAO, 0) AS DECIMAL(18,2))       AS X_VLRAQUIS, "
		+ " CAST(BEM.CODBEM AS CHAR)                                 AS X_CODBEM, "
		+ " CAST(BEM.CODPROD AS CHAR)                                AS X_CODPROD, "
		+ " CAST(BEM.CODEMP AS CHAR)                                 AS X_CODEMP, "
		+ " BEM.DESCRBEM                                             AS X_DESCRBEM, "
		+ " PRO.DESCRPROD                                            AS X_DESCRPROD, "
		+ " PRO.REFERENCIA                                           AS X_REFERENCIA, "
		+ " PRO.MARCA                                                AS X_MARCA, "
		+ " CAST(PRO.CODGRUPOPROD AS CHAR)                           AS X_CODGRUPO, "
		+ " IFNULL(GRU.DESCRGRUPOPROD, 'Sem grupo')                  AS X_GRUPO, "
		+ " IFNULL(EMP.NOMEFANTASIA, CONCAT('Empresa ', BEM.CODEMP)) AS X_EMPRESA ";

	String query = " SELECT " + cols
		+ " FROM TCIBEM BEM "
		+ " LEFT JOIN TGFPRO PRO ON PRO.CODPROD = BEM.CODPROD "
		+ " LEFT JOIN TGFGRU GRU ON GRU.CODGRUPOPROD = PRO.CODGRUPOPROD "
		+ " LEFT JOIN TSIEMP EMP ON EMP.CODEMP = BEM.CODEMP "
		+ w.toString()
		+ " ORDER BY BEM.CODBEM LIMIT " + LIMITE;

	out.println(query);
%>
</snk:query>
<table id="pat-raw">
	<thead>
		<c:forEach items="${bens.rows}" var="row" begin="0" end="0">
			<tr><c:forEach items="${row}" var="col"><th><c:out value="${col.key}"/></th></c:forEach></tr>
		</c:forEach>
	</thead>
	<tbody>
		<c:forEach items="${bens.rows}" var="row">
			<tr><c:forEach items="${row}" var="col"><td><c:out value="${col.value}"/></td></c:forEach></tr>
		</c:forEach>
	</tbody>
</table>
