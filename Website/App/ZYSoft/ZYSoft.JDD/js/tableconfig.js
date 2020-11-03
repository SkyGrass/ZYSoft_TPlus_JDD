const tableconf = [
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
},
{
    title: "单号",
    field: "FBillNo",
    hozAlign: "center",
    width: 150,
    headerSort: false
},
{
    title: "支付用户",
    field: "FPayUser",
    hozAlign: "center",
    width: 'auto',
    headerSort: false
},
{
    title: "酒类",
    field: "FInvName",
    hozAlign: "center",
    width: 150,
    headerSort: false
},
{
    title: "商铺名",
    field: "FCustomer",
    hozAlign: "center",
    width: 150,
    headerSort: false
},
{
    title: "设备号",
    field: "FDeviceNo",
    hozAlign: "center",
    width: 120,
    headerSort: false
},
{
    title: "代理",
    field: "FAgent",
    hozAlign: "center",
    width: 120,
    headerSort: false
},
{
    title: "所属代理",
    field: "FAgentCode",
    hozAlign: "center",
    width: 120,
    headerSort: false
},
{
    title: "省市区",
    field: "FAddress",
    hozAlign: "center",
    width: 120,
    headerSort: false
},
{
    title: "代理类型",
    field: "FAgentType",
    hozAlign: "center",
    width: 120,
    headerSort: false
},
{
    title: "规格两",
    field: "FSpecification",
    hozAlign: "center",
    width: 120,
    headerSort: false
},
{
    title: "优惠券",
    field: "FCoupon",
    hozAlign: "center",
    width: 120,
    headerSort: false
},
{
    title: "实付金额",
    field: "FAmount",
    hozAlign: "center",
    width: 120,
    headerSort: false
},
{
    title: "酒水销售",
    field: "FSellAmount",
    hozAlign: "center",
    width: 120,
    headerSort: false
},
{
    title: "店员奖励",
    field: "FStaffReward",
    hozAlign: "center",
    headerSort: false,
    width: 100,
},
{
    title: "个人代理分成",
    field: "FPersonalAgent",
    hozAlign: "center",
    headerSort: false,
    width: 120,
},
{
    title: "区县合伙人分成",
    field: "FPartner",
    hozAlign: "center",
    headerSort: false,
    width: 120
},
{
    title: "额外区县合伙人分成",
    field: "FAdditionalPartner",
    hozAlign: "right",
    width: 120,
    headerSort: false,
    editor: false,
},
{
    title: "订单状态",
    field: "FOrderStatus",
    hozAlign: "center",
    headerSort: false,
    width: 80
},
{
    title: "订单日期",
    field: "FOrderDate",
    hozAlign: "center",
    width: 120,
    headerSort: false,
    formatter: "datetime",
    formatterParams: {
        inputFormat: "YYYY-MM-DD",
        outputFormat: "YYYY-MM-DD",
        invalidPlaceholder: "",
    }
},
{
    title: "备注",
    field: "FMemo",
    hozAlign: "center",
    headerSort: false,
    width: 100
},
{
    title: "实际出酒ml",
    field: "FQuantity",
    hozAlign: "center",
    headerSort: false,
    width: 100
}
]

