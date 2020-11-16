const tableconfdef = [
    {
        title: "勾选",
        formatter: "rowSelection",
        titleFormatter: "rowSelection",
        hozAlign: "center",
        headerSort: false,
        frozen: true,
        cellClick: function (e, cell) {
            cell.getRow().toggleSelect();
        }
    },
    {
        title: "检查结果",
        field: "FIsValid",
        hozAlign: "center",
        formatter: "tickCross",
        width: 80,
        headerSort: false,
        editor: false,
    },
    {
        title: "原因",
        field: "FErrorMsg",
        hozAlign: "center",
        headerSort: false,
        width: 300,
        formatter: function (cell, formatterParams) {
            var value = cell.getValue() == null ? "" : cell.getValue();
            return value.indexOf('通过') > -1 ? "<span style='color:green; font-weight:bold;'>" + value + "</span>" :
                "<span style='color:red; font-weight:bold;'>" + value + "</span>";
        }
    }
]

