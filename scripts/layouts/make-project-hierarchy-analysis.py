#!/usr/bin/env python3
"""Generates the Excel layout of report 50101 "BGB Project Hierarchy Analysis".

openpyxl writes the Data sheet (table "Data", filled by BC with the report dataset), the Analysis sheet and a chart.
openpyxl cannot write pivot tables, so the pivot cache (source = table "Data", refreshOnLoad) and pivot table
definitions are added as raw SpreadsheetML parts afterwards. The cache is saved empty (saveData=0): Excel
rebuilds it from the Data table when the workbook opens, so the pivots always show the report's data.

Usage: scripts/layouts/make-project-hierarchy-analysis.py [output.xlsx]
"""
import json, os, re, sys, zipfile, shutil, tempfile
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill
from openpyxl.worksheet.table import Table, TableStyleInfo
from openpyxl.utils import get_column_letter
from openpyxl.chart import BarChart, Reference

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "app/src/ProjectAnalysis/ProjectHierarchyAnalysis.xlsx")
COLS = json.load(open(os.path.join(HERE, "project-hierarchy-analysis.columns.json")))
IDX = {c: i for i, c in enumerate(COLS)}

# (name, sheet, anchor cell, row fields, data fields (column, caption)); one pivot per sheet so they can grow freely
PIVOTS = [
    ("PivotByTopAndLevel", "Summary", "A5",
     ["TopLevelProjectNo", "Level"],
     [("BudgetPriceTotal", "Budget Price"), ("UsageCostTotal", "Usage Cost"), ("BillablePriceTotal", "Billable Price"), ("InvoicedPriceTotal", "Invoiced Price")]),
    ("PivotByBillTo", "By Customer", "A4",
     ["BillToCustomerNo", "BillToName"],
     [("BillablePriceTotal", "Billable Price"), ("InvoicedPriceTotal", "Invoiced Price"), ("BillableProfit", "Billable Profit")]),
    ("PivotBudgetVsActual", "By Project", "A4",
     ["SortKey", "ProjectNo"],
     [("BudgetCostTotal", "Budget Cost"), ("UsageCostTotal", "Usage Cost"), ("BudgetPriceTotal", "Budget Price"), ("BillablePriceTotal", "Billable Price"), ("InvoicedPriceTotal", "Invoiced Price")]),
]
CHART_SERIES = [("BudgetPriceTotal", "Budget Price"), ("UsageCostTotal", "Usage Cost"), ("InvoicedPriceTotal", "Invoiced Price")]

def build_base(path):
    wb = Workbook()
    titles = {"Summary": "Project Hierarchy Analysis: by top-level project and level",
              "By Customer": "By bill-to customer",
              "By Project": "Budget vs usage vs invoiced per project (tree order)"}
    first = True
    for name, sheet, anchor, rows, data in PIVOTS:
        ws = wb.active if first else wb.create_sheet(sheet)
        first = False
        ws.title = sheet
        ws["A1"] = titles[sheet]
        ws["A1"].font = Font(size=14, bold=True)
        ws["A2"] = "Pivot tables refresh from the Data sheet when the workbook is opened. Amounts in LCY, own values per project (sums per top-level project = hierarchy totals)."
        ws["A2"].font = Font(italic=True, color="666666")
        ws.column_dimensions["A"].width = 22
        ws.column_dimensions["B"].width = 30
        for c in range(3, 9):
            ws.column_dimensions[get_column_letter(c)].width = 16

    ds = wb.create_sheet("Data")
    for i, c in enumerate(COLS, 1):
        ds.cell(row=1, column=i, value=c)
    ref = f"A1:{get_column_letter(len(COLS))}2"
    t = Table(displayName="Data", ref=ref)
    t.tableStyleInfo = TableStyleInfo(name="TableStyleMedium2", showRowStripes=True)
    ds.add_table(t)
    ds.freeze_panes = "C2"
    for i, c in enumerate(COLS, 1):
        ds.column_dimensions[get_column_letter(i)].width = max(12, min(28, len(c) + 2))
        if i > 16:
            for row in range(2, 3):
                ds.cell(row=row, column=i).number_format = "#,##0.00"

    # Chart sheet: series point at defined names over the Data table columns (grow with the table)
    ch = wb.create_sheet("Chart")
    ch["A1"] = "Budget vs usage vs invoiced per project (own values, LCY)"
    ch["A1"].font = Font(size=12, bold=True)
    chart = BarChart()
    chart.type = "col"
    chart.title = "Budget vs usage vs invoiced"
    chart.y_axis.title = "LCY"
    chart.x_axis.title = "Project"
    chart.height, chart.width = 12, 26
    for col, cap in CHART_SERIES:
        c = IDX[col] + 1
        data = Reference(ds, min_col=c, min_row=1, max_row=2)
        chart.add_data(data, titles_from_data=True)
    chart.set_categories(Reference(ds, min_col=IDX["ProjectNo"] + 1, min_row=2, max_row=2))
    ch.add_chart(chart, "A3")
    # CaptionData, TranslationData and Aggregated Metadata are added by BC when rendering (pre-creating them
    # with openpyxl makes BC's ReportTextTableSheetStrategy fail).
    wb.save(path)

def cache_xml():
    fields = []
    axis_cols = {c for p in PIVOTS for c in p[3]}
    for c in COLS:
        if c in axis_cols:
            fields.append(f'<cacheField name="{c}" numFmtId="0"><sharedItems containsNonDate="0" containsBlank="1" count="2"><m/><s v="" u="1"/></sharedItems></cacheField>')
        else:
            fields.append(f'<cacheField name="{c}" numFmtId="0"><sharedItems containsNonDate="0" containsString="0" containsBlank="1"/></cacheField>')
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<pivotCacheDefinition xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:id="rId1" '
            'refreshOnLoad="1" createdVersion="8" refreshedVersion="8" minRefreshableVersion="3" recordCount="0">'
            '<cacheSource type="worksheet"><worksheetSource name="Data"/></cacheSource>'
            f'<cacheFields count="{len(COLS)}">' + "".join(fields) + '</cacheFields></pivotCacheDefinition>')

def records_xml():
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<pivotCacheRecords xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" count="0"/>')

def pivot_xml(name, anchor, rows, data, cache_id):
    col0 = ord(anchor[0]) - ord("A")
    row0 = int(anchor[1:])
    width = len(rows) + len(data)
    ref = f"{anchor}:{chr(ord('A') + col0 + width - 1)}{row0 + 2}"
    pf = []
    data_cols = {IDX[c] for c, _ in data}
    for i, c in enumerate(COLS):
        if c in rows:
            pf.append('<pivotField axis="axisRow" compact="0" outline="0" showAll="0" defaultSubtotal="0"><items count="2"><item m="1" x="1"/><item x="0"/></items></pivotField>')
        elif i in data_cols:
            pf.append('<pivotField dataField="1" compact="0" outline="0" showAll="0" defaultSubtotal="0"/>')
        else:
            pf.append('<pivotField compact="0" outline="0" showAll="0" defaultSubtotal="0"/>')
    row_fields = "".join(f'<field x="{IDX[c]}"/>' for c in rows)
    row_item = "<i>" + "".join('<x v="1"/>' for _ in rows) + "</i>"
    col_items = "".join(('<i><x/></i>' if k == 0 else f'<i i="{k}"><x v="{k}"/></i>') for k in range(len(data)))
    data_fields = "".join(f'<dataField name="{cap} " fld="{IDX[c]}" baseField="0" baseItem="0" numFmtId="4"/>' for c, cap in data)
    return ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
            '<pivotTableDefinition xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            f'name="{name}" cacheId="{cache_id}" applyNumberFormats="0" applyBorderFormats="0" applyFontFormats="0" '
            'applyPatternFormats="0" applyAlignmentFormats="0" applyWidthHeightFormats="1" dataCaption="Values" '
            'updatedVersion="8" minRefreshableVersion="3" itemPrintTitles="1" createdVersion="8" indent="0" '
            'compact="0" compactData="0" gridDropZones="1" multipleFieldFilters="0">'
            f'<location ref="{ref}" firstHeaderRow="1" firstDataRow="1" firstDataCol="{len(rows)}"/>'
            f'<pivotFields count="{len(COLS)}">' + "".join(pf) + '</pivotFields>'
            f'<rowFields count="{len(rows)}">{row_fields}</rowFields>'
            f'<rowItems count="2">{row_item}<i t="grand"><x/></i></rowItems>'
            '<colFields count="1"><field x="-2"/></colFields>'
            f'<colItems count="{len(data)}">{col_items}</colItems>'
            f'<dataFields count="{len(data)}">{data_fields}</dataFields>'
            '<pivotTableStyleInfo name="PivotStyleMedium9" showRowHeaders="1" showColHeaders="1" showRowStripes="0" showColStripes="0" showLastColumn="1"/>'
            '</pivotTableDefinition>')

def inject(base, out):
    tmp = tempfile.mkdtemp()
    with zipfile.ZipFile(base) as z:
        z.extractall(tmp)
    P = lambda *a: os.path.join(tmp, *a)
    wbx = open(P("xl/workbook.xml")).read()
    sheets = re.findall(r'<sheet [^>]*name="([^"]+)"[^>]*r:id="([^"]+)"', wbx)
    rels = open(P("xl/_rels/workbook.xml.rels")).read()
    target = {rid: t for rid, t in re.findall(r'Id="([^"]+)"[^>]*Target="([^"]+)"', rels)} or {}
    if not target:
        target = {rid: t for t, rid in re.findall(r'Target="([^"]+)"[^>]*Id="([^"]+)"', rels)}
    sheet_file = {n: target[rid].split("/")[-1] for n, rid in sheets}
    cache_id = 10
    os.makedirs(P("xl/pivotCache/_rels"), exist_ok=True)
    os.makedirs(P("xl/pivotTables/_rels"), exist_ok=True)
    open(P("xl/pivotCache/pivotCacheDefinition1.xml"), "w").write(cache_xml())
    open(P("xl/pivotCache/pivotCacheRecords1.xml"), "w").write(records_xml())
    open(P("xl/pivotCache/_rels/pivotCacheDefinition1.xml.rels"), "w").write(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/pivotCacheRecords" Target="pivotCacheRecords1.xml"/></Relationships>')
    for n, (name, sheet, anchor, rows, data) in enumerate(PIVOTS, 1):
        open(P(f"xl/pivotTables/pivotTable{n}.xml"), "w").write(pivot_xml(name, anchor, rows, data, cache_id))
        open(P(f"xl/pivotTables/_rels/pivotTable{n}.xml.rels"), "w").write(
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/pivotCacheDefinition" Target="../pivotCache/pivotCacheDefinition1.xml"/></Relationships>')
        rel = f'<Relationship Id="rIdPivot{n}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/pivotTable" Target="../pivotTables/pivotTable{n}.xml"/>'
        sheet_rels_path = P("xl/worksheets/_rels", sheet_file[sheet] + ".rels")
        os.makedirs(os.path.dirname(sheet_rels_path), exist_ok=True)
        if os.path.exists(sheet_rels_path):
            x = open(sheet_rels_path).read().replace("</Relationships>", rel + "</Relationships>")
        else:
            x = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + rel + "</Relationships>"
        open(sheet_rels_path, "w").write(x)
    rels = rels.replace("</Relationships>", '<Relationship Id="rIdPivotCache1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/pivotCacheDefinition" Target="pivotCache/pivotCacheDefinition1.xml"/></Relationships>')
    open(P("xl/_rels/workbook.xml.rels"), "w").write(rels)
    # defined names for the chart (structured references grow with the Data table)
    names = "".join(f'<definedName name="Chart{c}">Data[{c}]</definedName>' for c in ["ProjectNo"] + [c for c, _ in CHART_SERIES])
    wbx = wbx.replace("<definedNames/>", "").replace("<workbookProtection/>", "")
    if 'xmlns:r=' not in wbx.split(">", 1)[0]:
        wbx = wbx.replace('<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"', '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"', 1)
    if "<definedNames>" in wbx:
        wbx = wbx.replace("<definedNames>", "<definedNames>" + names)
    else:
        wbx = wbx.replace("</sheets>", "</sheets><definedNames>" + names + "</definedNames>")
    pc = f'<pivotCaches><pivotCache cacheId="{cache_id}" r:id="rIdPivotCache1"/></pivotCaches>'
    wbx = re.sub(r"(<calcPr[^>]*/>)", r"\1" + pc, wbx) if "<calcPr" in wbx else wbx.replace("</workbook>", pc + "</workbook>")
    open(P("xl/workbook.xml"), "w").write(wbx)
    # chart series -> defined names
    for root, _, files in os.walk(P("xl/charts")):
        for f in files:
            cp = os.path.join(root, f)
            x = open(cp).read()
            def to_name(m):
                col = m.group(1)
                n = sum((ord(ch) - 64) * 26 ** k for k, ch in enumerate(reversed(col))) - 1
                return f"<f>[0]!Chart{COLS[n]}</f>"
            # data and category ranges ('Data'!$X$2) -> defined names; series titles ('Data'!X1) stay
            x = re.sub(r"<f>'Data'!\$([A-Z]+)\$2</f>", to_name, x)
            open(cp, "w").write(x)
    ct = open(P("[Content_Types].xml")).read()
    ct = ct.replace("</Types>",
        '<Override PartName="/xl/pivotCache/pivotCacheDefinition1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheDefinition+xml"/>'
        '<Override PartName="/xl/pivotCache/pivotCacheRecords1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.pivotCacheRecords+xml"/>'
        + "".join(f'<Override PartName="/xl/pivotTables/pivotTable{n}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.pivotTable+xml"/>' for n in range(1, len(PIVOTS) + 1))
        + "</Types>")
    open(P("[Content_Types].xml"), "w").write(ct)
    if os.path.exists(out):
        os.remove(out)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(P("[Content_Types].xml"), "[Content_Types].xml")
        for root, _, files in os.walk(tmp):
            for f in files:
                full = os.path.join(root, f)
                arc = os.path.relpath(full, tmp)
                if arc != "[Content_Types].xml":
                    z.write(full, arc)
    shutil.rmtree(tmp)

if __name__ == "__main__":
    base = tempfile.mktemp(suffix=".xlsx")
    build_base(base)
    inject(base, OUT)
    os.remove(base)
    print("wrote", OUT)
