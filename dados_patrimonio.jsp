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
	Dados do Dashboard de Patrimonio - TCIBEM
	-------------------------------------------------------------------------
	Arquivo separado (chamado via XMLHttpRequest pelo patrimonio.jsp, depois
	que a casca da tela ja carregou) para que o spinner de "carregando" cubra
	a espera real da consulta no banco. Nao ha HTML de pagina aqui - so a
	tabela de dados brutos que o JS de patrimonio.jsp le e descarta.

	A consulta traz TODAS as colunas de TCIBEM (BEM.*) e cria apelidos X_*
	para os campos usados nos indicadores. As colunas sao lidas dinamicamente
	do resultado, entao campos customizados (AD_CHASSI, AD_PLACA, etc.)
	aparecem automaticamente na grade e na busca livre.
	=========================================================================
--%>

<%
	int LIMITE = 20000;   // teto de registros carregados na tela (Oracle)
%>

<snk:query var="bens">
<%
	StringBuffer w = new StringBuffer(
		" WHERE BEM.CODBEM IS NOT NULL "
		+ " AND TRIM(TO_CHAR(BEM.CODBEM)) IS NOT NULL "
		+ " AND UPPER(TRIM(TO_CHAR(BEM.CODBEM))) <> '<TODOS>' "
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
		+ " TO_CHAR(BEM.DTCOMPRA, 'YYYY-MM-DD')                      AS X_DTCOMPRA, "
		+ " TO_CHAR(BEM.DTBAIXA, 'YYYY-MM-DD')                       AS X_DTBAIXA, "
		+ " TO_CHAR(NVL(BEM.VLRAQUISICAO, 0), 'FM99999999999990.00') AS X_VLRAQUIS, "
		+ " TO_CHAR(BEM.CODBEM)                                      AS X_CODBEM, "
		+ " TO_CHAR(BEM.CODPROD)                                     AS X_CODPROD, "
		+ " TO_CHAR(BEM.CODEMP)                                      AS X_CODEMP, "
		+ " BEM.DESCRBEM                                             AS X_DESCRBEM, "
		+ " PRO.DESCRPROD                                            AS X_DESCRPROD, "
		+ " PRO.REFERENCIA                                           AS X_REFERENCIA, "
		+ " PRO.MARCA                                                AS X_MARCA, "
		+ " TO_CHAR(PRO.CODGRUPOPROD)                                AS X_CODGRUPO, "
		+ " NVL(GRU.DESCRGRUPOPROD, 'Sem grupo')                     AS X_GRUPO, "
		+ " NVL(EMP.NOMEFANTASIA, 'Empresa ' || BEM.CODEMP)          AS X_EMPRESA ";

	String query = " SELECT * FROM ( SELECT " + cols
		+ " FROM TCIBEM BEM "
		+ " LEFT JOIN TGFPRO PRO ON PRO.CODPROD = BEM.CODPROD "
		+ " LEFT JOIN TGFGRU GRU ON GRU.CODGRUPOPROD = PRO.CODGRUPOPROD "
		+ " LEFT JOIN TSIEMP EMP ON EMP.CODEMP = BEM.CODEMP "
		+ w.toString()
		+ " ORDER BY BEM.CODBEM ) WHERE ROWNUM <= " + LIMITE;

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
