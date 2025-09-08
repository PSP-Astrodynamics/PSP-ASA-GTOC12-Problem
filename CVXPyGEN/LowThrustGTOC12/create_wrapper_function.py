from bs4 import BeautifulSoup

header = """
#include "mex.h"
#include "cpg_workspace.h"
#include "cpg_solve.h"

// MEX gateway function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
"""

def main():
    with open("Ast2Ast_fixed_FOH_PTR_ECOS/README.html") as f:
        data = f.read()
    doc = BeautifulSoup(data, features="html.parser")

    inputs_table = doc.find_all("table")[0]
    output_prim = doc.find_all("table")[1]
    output_dual = doc.find_all("table")[2]
    input_vars = []
    output_prim_vars = []
    output_dual_vars = []

    for row in inputs_table.find_all('tr'):
        if row.find_all('td'):
            param, dim = row.find_all('td')
            param = param.text
            size = int(dim.text.split('(')[1].split(')')[0])

            input_vars.append((param, size))

    for row in output_prim.find_all('tr'):
        if row.find_all('td'):
            param, dim = row.find_all('td')
            param = param.text
            if 'by' in dim.text:
                rows = int(dim.text.split(' by')[0])
                cols = int(dim.text.split('by ')[1].split('(')[0])
            else:
                rows = int(dim.text)
                cols = 1

            output_prim_vars.append((param, rows, cols))

    for row in output_dual.find_all('tr'):
        if row.find_all('td'):
            param, dim = row.find_all('td')
            param = param.text
            if 'by' in dim.text:
                rows = int(dim.text.split(' by')[0])
                cols = int(dim.text.split('by ')[1].split('(')[0])
            else:
                rows = int(dim.text)
                cols = 1

            output_dual_vars.append((param, rows, cols))


    with open('cpg_solve_wrap.c', 'w+') as f:
        f.write(header)
        f.write(f"""
    // Check number of inputs
    if (nrhs != {len(input_vars)}) {{
        mexErrMsgIdAndTxt("MATLAB:cpg_solve:nrhs", "{len(input_vars)} inputs required.");
    }}

    // Check number of outputs
    if (nlhs != {len(output_prim_vars) + len(output_dual_vars)}) {{
        mexErrMsgIdAndTxt("MATLAB:cpg_solve:nlhs", "{len(output_prim_vars) + len(output_dual_vars)} outputs required.");
    }}
        """)

        for input_var_idx, (input_var, input_size) in enumerate(input_vars):
            f.write(f"""
    double * {input_var} = mxGetPr(prhs[{input_var_idx}]);
    for (int i = 0; i < {input_size}; i++) {{
        cpg_update_{input_var}(i, {input_var}[i]);
    }}
            """)

        f.write("\n    // Solve the problem instance\n    cpg_solve();")

        for output_var_idx, (output_var, output_rows, output_cols) in enumerate(output_prim_vars):
            f.write(f"""
    plhs[{output_var_idx}] = mxCreateDoubleMatrix({output_rows}, {output_cols}, mxREAL);
    double * {output_var} = mxGetPr(plhs[{output_var_idx}]);
    for (int i = 0; i < {output_rows * output_cols}; i++) {{
        {output_var}[i] = CPG_Result.prim->{output_var}[i];
    }}
            """)

        for output_var_idx, (output_var, output_rows, output_cols) in enumerate(output_dual_vars):
            f.write(f"""
    plhs[{output_var_idx + len(output_prim_vars)}] = mxCreateDoubleMatrix({output_rows}, {output_cols}, mxREAL);
    double * {output_var} = mxGetPr(plhs[{output_var_idx + len(output_prim_vars)}]);
    for (int i = 0; i < {output_rows * output_cols}; i++) {{
        {output_var}[i] = CPG_Result.dual->{output_var}[i];
    }}
            """)

        f.write("\n}\n")


if __name__ == '__main__':
    main()