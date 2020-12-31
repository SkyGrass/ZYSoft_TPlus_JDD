var vm = new Vue({
    el: "#app",
    data: function () {
        return {
            forbidden: true,
            gridConfig: [],
            persons: [],
            customers: [],
            customers_bark: [],
            user: [{ code: loginUserCode, name: loginName }],
            loading: false,
            grid: {},
            tableData: [],
            tableData_bark: [],
            form: {
                FUserCode: loginUserCode,
                FUserName: loginName,
                FDate: new Date(),
                FCustomer: "",
                FCustCode: "",
                FMemo: ""
            }
        };
    },
    methods: {
        uploadSuccess(response, file, fileList) {
            this.forbidden = true;
            if (response.state == "success") {
                this.tableData = response.data;
                this.tableData_bark = response.data;
                this.customers = response.customers;
                if (this.customers.length > 0) {
                    this.form.FCustomer = this.customers[0]
                    this.filterRecord(this.customers[0])
                }
                this.customers_bark = response.customers;
            }
            this.loading = false;
            return this.$message({
                message: response.data.length > 0 ? '导入完成!' : response.msg,
                type: response.data.length > 0 ? 'success' : 'warning'
            });
        },
        uploadBefore(file) {
            this.loading = true;
        },
        checkTable() {
            const that = this;
            that.forbidden = true;
            if (this.tableData.length <= 0) return;
            this.loading = true;
            var temp = this.grid.getSelectedData()
            if (temp.length <= 0) {
                this.loading = false;
                return that.$message({
                    message: '请先勾选行!',
                    type: 'warning'
                });
            } else {
                this.loading = true;
                $.ajax({
                    type: "POST",
                    url: "uploadhandler.ashx",
                    async: true,
                    data: { SelectApi: "check", dataSource: JSON.stringify(temp) },
                    dataType: "json",
                    success: function (response) {
                        that.loading = false;
                        if (response.state == "success") {
                            that.tableData = response.data;
                        }
                        that.forbidden = !response.data.every(function (f) { return f.FIsValid })
                        that.loading = false;
                        return that.$message({
                            message: response.data.length > 0 ? '检查完成!' : '未能检查数据!',
                            type: response.data.length > 0 ? 'success' : 'warning'
                        });
                    },
                    error: function () {
                        that.loading = false;
                        return that.$message({
                            message: '未能正确检查数据!',
                            type: 'warning'
                        });
                    }
                });
            }
        },
        beforeSave() {
            var that = this;
            var result = false;
            const array = this.grid.getSelectedData();
            if (this.form.FDate == null) {
                result = true;
                this.$message({
                    message: '尚未指定日期,请核实!',
                    type: 'warning'
                });
            }
            if (this.form.FUserCode == "") {
                result = true;
                this.$message({
                    message: '尚未选择制单人,请核实!',
                    type: 'warning'
                });
            }
            if (array.length <= 0) {
                result = true;
                that.$message({
                    message: '请先勾选行!',
                    type: 'warning'
                });
            }
            if (array.some(function (f) { return f.FIsValid == false })) {
                result = true;
                this.$message({
                    message: '检查未通过,请核实!',
                    type: 'warning'
                });
            }
            return result;
        },
        saveTable() {
            var that = this;
            if (!this.beforeSave()) {
                var temp = this.grid.getSelectedData().map(function (m) {
                    return {
                        FInvCode: m.FInvCode,
                        FQuantity: m.FSpecification,
                        FAmount: Number(m.FAmount6) + Number(m.FStaffRewardLiang) / 2,
                        FMemo: m.FBillNo,
                        FCustCode: m.FCustCode
                    }
                });

                if (temp.length > 0) {
                    that.$confirm('此操作将提交数据, 是否继续?', '提示', {
                        confirmButtonText: '确定',
                        cancelButtonText: '取消',
                        type: 'warning'
                    }).then(function () {
                        that.form.FCustCode = temp[0]["FCustCode"];
                        that.loading = true;
                        $.ajax({
                            type: "POST",
                            url: "uploadhandler.ashx",
                            async: true,
                            data: {
                                SelectApi: "save", formData: JSON.stringify(Object.assign({}, that.form, {
                                    FDate: moment(that.form.FDate).format("YYYY-MM-DD")
                                }, { Entry: temp }))
                            },
                            dataType: "json",
                            success: function (result) {
                                that.loading = false;
                                if (result.status == "success") {
                                    that.forbidden = true;
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
                    }).catch(function () {
                        that.$message({
                            type: 'info',
                            message: '已取消提交数据'
                        });
                    });
                } else {
                    this.$message({
                        message: '尚未勾选行记录,请核实!',
                        type: 'warning'
                    });
                }
            }
        },
        filterRecord(val) {
            var self = this;
            this.loading = true;
            setTimeout(function () {
                self.tableData = self.tableData_bark.filter(function (item) {
                    return item.FCustomer.indexOf(val) > -1;
                });
                self.loading = false;
            }, 200);
        },
        remoteMethod(query) {
            var self = this;
            if (query !== '') {
                setTimeout(function () {
                    self.customers = self.customers_bark.filter(function (item) {
                        return item.indexOf(query) > -1;
                    });
                }, 200);
            } else {
                self.customers = self.customers_bark;
            }
        },
        initGrid() {
            var that = this;
            $.ajax({
                type: "POST",
                url: "uploadhandler.ashx",
                async: true,
                data: { SelectApi: "config" },
                dataType: "json",
                success: function (response) {
                    that.loading = false;
                    if (response.state == "success") {
                        var configList = response.data;
                        var t = tableconfdef.concat(configList.map(function (config) {
                            var cof = tableconf.find(function (conf) {
                                return conf.field == config.field
                            });
                            if (cof) {
                                config = Object.assign({}, config, cof[0]);
                            }
                            return config;
                        }));
                    }
                    that.gridConfig = t;
                    that.loading = false;
                },
                error: function () {
                    that.loading = false;
                    return that.$message({
                        message: '未能正确获取表格配置!',
                        type: 'warning'
                    });
                }
            });
        }
    },
    watch: {
        tableData: {
            handler: function (newData) {
                this.grid.replaceData(newData);
            },
            deep: true
        }, gridConfig: {
            handler: function (newData) {
                this.grid.setColumns(newData);
                this.grid.redraw(true);
            },
            deep: true
        }
    },
    mounted() {
        var that = this;
        that.initGrid();
        this.maxHeight = ($(window).height() - $("#header").height())
        window.onresize = function () {
            that.maxHeight = ($(window).height() - $("#header").height())
        }
        this.grid = new Tabulator("#grid", {
            height: this.maxHeight,
            layout: "fitColumns",
            columnHeaderVertAlign: "bottom",
            selectable: 9999, //make rows selectable
            data: this.tableData, //set initial table data
            columns: this.gridConfig
        })
    }
});