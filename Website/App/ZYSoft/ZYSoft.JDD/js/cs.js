var vm = new Vue({
    el: "#app",
    data: function () {
        return {
            loading: false,
            grid: {},
            gridDetail: {},
            tableData: [],
            tableDataDetail: [],
            showPicker: false,
            form: {
                date: [moment().format('YYYY-MM-DD'), moment().format('YYYY-MM-DD')],
                ordercode: "",
                customer: "",
            },
            curidBom: -1,
            curRow: {},
            curidDetailRow: -1,
            postForm: {
                FSOBillID: -1,
                FSOBillEntryID: -1,
                FUserCode: loginUserCode,
                FUserName: loginName,
                FInvCode: "",
                FVersion: "",
            },
            detail: {
                id: 2,
                code: "1002001",
                name: "三文鱼柳",
                version: "1",
                idinventory: 36,
                cinvcode: "2001006",
                cinvname: "三文鱼",
                cinvstd: "",
                cunit: "KG",
                requiredquantity: 1.68000000000000
            },
            materialInfo: [],
            materialInfo_bark: [],
            multipleSelection: [],
            maxHeightForDia: 0,
            querMaterialform: {
                keyword: ""
            }
        };
    },
    methods: {
        clearTable() {
            this.tableData = [];
        },
        initPostForm() {
            var that = this;
            that.postForm.FSOBillID = -1;
            that.postForm.FSOBillEntryID = -1;
            that.postForm.FInvCode = -1;
            that.postForm.FVersion = -1;
            that.curidBom == -1
            that.tableData = []
            that.tableDataDetail = []
            that.curRow = {}
        },
        queryMaterial() {
            var that = this;
            $.ajax({
                type: "POST",
                url: "cshandler.ashx",
                async: true,
                data: Object.assign({}, { SelectApi: "getallmaterialinfo" }),
                dataType: "json",
                success: function (result) {
                    if (result.status == "success") {
                        that.materialInfo = result.data;
                        that.materialInfo_bark = result.data;
                    } else {
                        return that.$message({
                            message: '未能查询到存货信息!',
                            type: 'warning'
                        });
                    }

                    that.loading = false;
                },
                error: function () {
                    that.loading = false;
                }
            });
        },
        remoteQueryMaterial(query) {
            var that = this;
            if (query !== '') {
                this.loading = true;
                setTimeout(function () {
                    that.loading = false;
                    that.materialInfo = $.extend(true, [], that.materialInfo_bark).filter(function (item) {
                        return (item.invcode.toLowerCase()
                          .indexOf(query.toLowerCase()) > -1 ||
                            item.invname.toLowerCase()
                          .indexOf(query.toLowerCase()) > -1);
                    });
                }, 200);
            } else {
                this.materialInfo = this.materialInfo_bark;
            }
        },
        handleSelectionChange(val) {
            this.multipleSelection = val;
        },
        queryOrder() {
            var that = this;
            //if (this.form.ordercode == "") {
            //    result = true;
            //    this.$message({
            //        message: '请先填写销售订单号!',
            //        type: 'warning'
            //    });
            //}
            if (this.form.date == null) {
                result = true;
                this.$message({
                    message: '尚未指定日期,请核实!',
                    type: 'warning'
                });
            }
            that.loading = true;
            this.initPostForm();
            var formData = Object.assign({}, this.form);
            if (this.form.date != null) {
                formData.begindate = this.form.date[0];
                formData.endate = this.form.date[1]
            }
            $.ajax({
                type: "POST",
                url: "cshandler.ashx",
                async: true,
                data: Object.assign({}, { SelectApi: "getorder" }, formData),
                dataType: "json",
                success: function (result) {
                    if (result.status == "success") {
                        that.tableData = result.data;
                    } else {
                        that.$message({
                            message: '未能查询到销售订单信息!',
                            type: 'warning'
                        });
                    }

                    that.loading = false;
                },
                error: function () {
                    that.loading = false;
                }
            });
        },
        queryOrderDetail(idbom) {
            var that = this;
            that.curidBom = idbom;
            $.ajax({
                type: "POST",
                url: "cshandler.ashx",
                async: true,
                data: { SelectApi: "getorderdetail", idbom},
                        dataType: "json",
                        success: function (result) {
                            if (result.status == "success") {
                                that.tableDataDetail = result.data.map(function (ele, index) {
                                    ele.index = index;
                                    return ele;
                                });
                            } else {
                                return that.$message({
                                    message: '未能查询到销售订单的物料信息!',
                                    type: 'warning'
                                });
                            }
                        },
                error: function () {
                }
            });
        },
        handleGetPerson() {
            var that = this;
            $.ajax({
                type: "POST",
                url: "zkmthandler.ashx",
                async: true,
                data: { SelectApi: "getperson" },
                dataType: "json",
                success: function (result) {
                    if (result.status == "success") {
                        that.persons = result.data;
                        if (that.persons.length > 0) {
                            that.form.FPersonCode = that.persons[0]["code"];
                        }
                    } else {
                        return that.$message({
                            message: '未能查询到请购人信息!',
                            type: 'warning'
                        });
                    }
                },
                error: function () {
                }
            });
        },
        confirm() {
            var that = this;
            if (this.multipleSelection.length > 0) {
                var currentRowCount = this.tableDataDetail.length + 1;
                var temp = $.extend(true, [], this.multipleSelection).map(function (selected, index) {
                    var item = {
                        id: -1,
                        index: currentRowCount,
                        code: selected.code,
                        name: selected.name,
                        version: that.curRow.version,
                        idinventory: that.curRow.idinventory,
                        cinvcode: that.curRow.cinvcode,
                        cinvname: that.curRow.cinvname,
                        cinvstd: that.curRow.cinvstd,
                        cunit: that.curRow.cunit,
                        requiredquantity: 0
                    };

                    return item;
                });

                if (temp.length > 0) {
                    this.tableDataDetail = this.tableDataDetail.concat(temp)
                } else {
                    that.$message({
                        message: '请先勾选存货!',
                        type: 'warning'
                    });
                }

                this.showPicker = temp.length <= 0
            } else {
                that.$message({
                    message: '请先勾选存货!',
                    type: 'warning'
                });
            }
        },
        addRow() {
            const that = this;
            if (this.curidBom != -1) {
                this.multipleSelection = [];
                this.showPicker = true;
            }
        },
        delRow() {
            const that = this;
            if (that.curidDetailRow != -1) {
                this.$confirm('此操作将删除记录行, 是否继续?', '提示', {
                    confirmButtonText: '确定',
                    cancelButtonText: '取消',
                    type: 'warning'
                }).then(function () {
                    var position = that.tableDataDetail.findIndex(
                        function (f) {
                            return f.index == that.curidDetailRow;
                        });
                    if (position > -1) {
                        that.tableDataDetail.splice(position, 1);
                        that.$message({
                            type: 'success',
                            message: '删除成功!'
                        });
                    }
                }).catch(function () {
                    that.$message({
                        type: 'info',
                        message: '已取消删除'
                    });
                });
            }
        },
        beforeSave() {
            var that = this;
            var result = false;
            const array = this.grid.getSelectedData();


            if (this.form.FUserCode == "") {
                result = true;
                this.$message({
                    message: '尚未选择制单人,请核实!',
                    type: 'warning'
                });
            }

            if (this.tableDataDetail.some(function (row) {
               return Number(row.requiredquantity) <= 0
            })) {
                return this.$alert('发现数量小于0的数据,请核查数量!', '错误', {
                    confirmButtonText: '确定'
                });
            }

            return result;
        },
        saveTable() {
            var that = this;
            if (!this.beforeSave()) {
                var temp = this.tableDataDetail.map(function (m) {
                    return {
                        FInvCode: m.cinvcode,
                        FQuantity: Number(m.requiredquantity)
                    }
                });

                if (temp.length > 0) {
                    this.$prompt('请输入新的版本号', '提示', {
                        closeOnClickModal: false,
                        inputValue: that.curRow.code,
                        inputPlaceholder: '请输入新的版本号',
                        confirmButtonText: '确定',
                        cancelButtonText: '取消',
                        inputErrorMessage: '输入不能为空',
                        inputValidator: function (value) {
                            if (!value) {
                                return '输入不能为空';
                            }
                        },
                        callback: function (action, instance) {
                            if (action === 'confirm') {
                                $.ajax({
                                    type: "POST",
                                    url: "cshandler.ashx",
                                    async: true,
                                    data: { SelectApi: "save", formdata: JSON.stringify(Object.assign({}, that.postForm, { BomEntry: temp })) },
                                    dataType: "json",
                                    success: function (result) {
                                        that.loading = false;
                                        if (result.status == "success") {
                                            that.initPostForm();
                                            return that.$message({
                                                message: result.msg,
                                                type: 'success'
                                            });
                                        } else {
                                            return that.$message({
                                                message: result.msg,
                                                type: 'warning'
                                            });
                                        }
                                    },
                                    error: function () {
                                        that.loading = false;
                                        that.$message({
                                            message: '保存单据失败,请检查!',
                                            type: 'warning'
                                        });
                                    }
                                })
                            }
                        }
                    })

                } else {
                    this.$message({
                        message: '尚未勾选行记录,请核实!',
                        type: 'warning'
                    });
                }
            }
        },
    },
    watch: {
        tableData: {
            handler: function (newData) {
                this.grid.replaceData(newData);
            },
            deep: true
        },

        tableDataDetail: {
            handler: function (newData) {
                this.gridDetail.replaceData(newData);
            },
            deep: true
        }
    },
    computed: {
        forbiddenUse() {
            return this.postForm.FSOBillID == -1
        },
        forbiddenDelete() {
            return this.postForm.FSOBillID == -1 ||
                this.curidBom == -1 || this.curidDetailRow == -1
        },
    },
    created() {
        this.queryMaterial();
    },
    mounted() {
        var that = this;

        this.maxHeight = ($(window).height() - $("#header").height() - 100)
        this.maxHeightForDia = this.maxHeight - 50
        window.onresize = function () {
            that.maxHeight = ($(window).height() - $("#header").height())
            that.maxHeightForDia = this.maxHeight - 50
        }

        tableconf_main.splice(0, 0, {
            title: "操作",
            field: "action",
            width: 100,
            align: "center",
            headerSort: false,
            formatter: function (cell, formatterParams) {
                const rowData = cell.getRow().getData();
                if (rowData.idbom)
                    return "<button>选择</button>";
            },
            cellClick: function (e, cell) {
                const rowData = cell.getRow().getData();
                if (rowData.idbom) {
                    that.curRow = rowData;
                    that.postForm.FSOBillID = rowData.id;
                    that.postForm.FSOBillEntryID = rowData.identry;
                    that.postForm.FInvCode = rowData.cinvcode;
                    that.postForm.FVersion = rowData.version;
                    that.queryOrderDetail(rowData.idbom)
                } else {
                    that.$message({
                        message: '当前销售订单没设置物料清单,请检查!',
                        type: 'warning'
                    });
                }
            }
        })

        this.grid = new Tabulator("#grid", {
            height: this.maxHeight,
            columnHeaderVertAlign: "bottom",
            data: this.tableData, //set initial table data
            columns: tableconf_main,
            selectable: 1,
            rowDblClick1: function (e, row) {
                row.toggleSelect()
                const rowData = row.getData();
                console.log(rowData)
                if (rowData.idbom) {

                    that.postForm.FSOBillID = rowData.id;
                    that.postForm.FSOBillEntryID = rowData.identry;

                    that.queryOrderDetail(rowData.idbom)
                } else {
                    that.$message({
                        message: '当前销售订单没设置物料清单,请检查!',
                        type: 'warning'
                    });
                }
            }
        })

        this.gridDetail = new Tabulator("#gridDetail", {
            height: this.maxHeight,
            index: "index",
            selectable: 1,
            columnHeaderVertAlign: "bottom",
            data: this.tableDataDetail, //set initial table data
            columns: tableconf_detail,
            rowClick: function (e, row) {
                const rowData = row.getData();
                console.log(rowData)
                that.curidDetailRow = rowData.index;
            }
        })
    }
});