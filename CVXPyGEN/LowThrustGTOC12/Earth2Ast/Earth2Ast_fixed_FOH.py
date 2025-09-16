import numpy as np
import cvxpy as cp
from cvxpygen import cpg
import time
import pickle


#from Code.Discretization.discretize import discretize_dynamics_ZOH

save = True;
load = False;

if not load:
    # Input from matlab
    x_ref = np.array(x_ref)
    u_ref = np.array(u_ref)
    p_ref = np.array(p_ref)

    x_0 = np.array(x_0).reshape(-1, 1)
    x_f = np.array(x_f).reshape(-1, 1)

    # Problem parameters
    #T_max = np.array(params[1])
    N = int(N);
    delta_t = np.array(delta_t)

    # PTR parameters
    w_vc = np.array(w_vc)
    w_tr = np.array(w_tr)

    ### Discretization
    A_k = np.array(A_k)
    B_k_minus = np.array(B_k_minus)
    B_k_plus = np.array(B_k_plus)
    c_k = np.array(c_k)
else:
    loaded_data = np.load(r'C:\Users\thatf\OneDrive\Documents\ASA\PSP-ASA-GTOC12-Problem\CVXPyGEN\LowThrustGTOC12\saved_Earth2Ast_input_FOH.npz', allow_pickle=True)
    x_ref = loaded_data["x_ref"]
    u_ref = loaded_data["u_ref"]
    #p_ref = loaded_data["p_ref"]

    x_0 = loaded_data["x_0"]
    x_f = loaded_data["x_f"]

    # Problem parameters
    N = loaded_data["N"]
    delta_t = loaded_data["delta_t"]

    # PTR parameters
    w_vc = loaded_data["w_vc"]# / 1000
    w_tr = loaded_data["w_tr"]

    # Discretization
    A_k = loaded_data["A_k"]
    B_k_minus = loaded_data["B_k_minus"]
    B_k_plus = loaded_data["B_k_plus"]
    c_k = loaded_data["c_k"]

    # Saved Problem
    dbfile = open(r'C:\Users\thatf\OneDrive\Documents\ASA\PSP-ASA-GTOC12-Problem\CVXPyGEN\LowThrustGTOC12\Earth2Ast_prob_FOH', 'rb')    
    problem = pickle.load(dbfile)

    dbfile.close()

t_k = np.linspace(0, N * delta_t, N + 1)

nx = 7
nu = 3
n_r = 3

m_star = 3000 # [kg]
Isp = 4000 # [s]
g_0 = 9.80665 # [m / s2]
alpha = 1 / (Isp * g_0) # [s / m]

AU = 1.49579151285e8 # [km]
l_star = AU # [km]
mu_star = 1.32712440018e11 # [km3 / s2]
t_star = np.sqrt(l_star ** 3 / mu_star); # [s]
v_star = np.sqrt(mu_star/l_star);

v_max_nd = 6 / v_star;

def virtual_control_cost_func(w_vc, V, v_0, v_N):
    J_vc = w_vc * (cp.sum(cp.norm(V, 1, 0)) + cp.norm(v_0, 1) + cp.norm(v_N, 1))
    return J_vc

def trust_region_cost_func(w_tr, eta):
    J_tr = w_tr @ eta.T
    return J_tr


def virtual_control_cost_func_np(w_vc, V, v_0, v_N):
    J_vc = w_vc * (np.sum(np.linalg.norm(V, 1, 0)) + np.linalg.norm(v_0, 1) + np.linalg.norm(v_N, 1))
    return J_vc


## Create Convex Problem
# Define variables
if str(type(problem)) == "<class 'array.array'>" or str(type(problem)) == "<class 'numpy.ndarray'>":
    #print("Creating problem")
    X = cp.Variable((nx, N + 1), name='X')
    U = cp.Variable((nu, N + 1), name='U')
    p = cp.Variable((3, 1), name = 'p')
    eta = cp.Variable((1, N + 1), name = 'eta')
    V = cp.Variable((nx, N + 0), name = 'V')
    v_0 = cp.Variable((nx, 1), name = 'v_0')
    v_N = cp.Variable((nx - 1, 1), name = 'v_N')

    # Define parameters
    #Ak_param = cp.Parameter((nx, nx, N + 0), name = 'Ak')
    #Bk_param = cp.Parameter((nx, nu, N + 0), name = 'Bk')
    ck_param = cp.Parameter((nx, N + 0), name = 'ck')
    x_0_param = cp.Parameter((nx, 1), name = 'x_0')
    x_f_param = cp.Parameter((nx - 1, 1), name = 'x_f')

    x_ref_param = cp.Parameter((nx, N + 1), name = 'x_ref')
    u_ref_param = cp.Parameter((nu, N + 1), name = 'u_ref')
    #p_ref_param = cp.Parameter((3, N + 1), name = 'p_ref')

    # Define objective
    objective = cp.Minimize(alpha / m_star * t_star * cp.sum((cp.norm(U[:, 0:-1], 2, 0) + cp.norm(U[:, 1:], 2, 0)) / 2) * delta_t)
    virtual_control_cost = cp.Minimize(virtual_control_cost_func(w_vc, V, v_0, v_N))
    trust_region_cost = cp.Minimize(trust_region_cost_func(w_tr, eta))
    augmented_objective = objective + virtual_control_cost + trust_region_cost

    # Define constraints
    m_i = 6

    T_max = 0.6 # [N]
    m_min = 500 / m_star # []

    Ak_params = []
    Bk_minus_params = []
    Bk_plus_params = []
    dynamics_constraints = []
    for k in range(N):
        Ak_params.append(cp.Parameter((nx, nx), name = "Ak_" + str(k)))
        Bk_plus_params.append(cp.Parameter((nx, nu), name = "Bk_plus_" + str(k)))
        Bk_minus_params.append(cp.Parameter((nx, nu), name = "Bk_minus_" + str(k)))

        dynamics_constraints.append(X[:, k + 1] == Ak_params[k] @ X[:, k] + Bk_minus_params[k] @ U[:, k] + Bk_plus_params[k] @ U[:, k + 1] + ck_param[:, k] + V[:, k])


    #dynamics_constraints = []
    #for k in range(N):
    #    dynamics_constraints.append(X[:, k + 1] == Ak_param[:, :, k] @ X[:, k] + Bk_param[:, :, k] @ U[:, k] + ck_param[:, 0, k] + V[:, k])

    constraints = dynamics_constraints + [ # Dynamics constraint
                   cp.norm2(U, 0) <= T_max, # Max thrust constraint
                   X[m_i, :] >= m_min, # Min mass constraint
                   cp.norm2(p) <= v_max_nd, # Departure velocity constraint
                   X[0:3, 0] + v_0[0:3] == x_0_param[0:3].flatten(), X[3:6, 0] + v_0[3:6] == p.flatten() + x_0_param[3:6].flatten(), X[6, 0] + v_0[6] == x_0_param[6].flatten(), # Initial condition constraint
                   X[0:6, N] + v_N == x_f_param.flatten(), # Terminal condition constraint
                   cp.sum(cp.sum_squares(X - x_ref_param)) + cp.sum(cp.sum_squares(U - u_ref_param)) <= eta]

    # Define problem
    problem = cp.Problem(augmented_objective, constraints)



# Save input data so it can be debugged in python
if save:
    np.savez(r'C:\Users\thatf\OneDrive\Documents\ASA\PSP-ASA-GTOC12-Problem\CVXPyGEN\LowThrustGTOC12\saved_Earth2Ast_input_FOH.npz', A_k = A_k, B_k_minus = B_k_minus, B_k_plus = B_k_plus, c_k = c_k, w_vc = w_vc, w_tr = w_tr, delta_t = delta_t, N = N, x_0 = x_0, x_f = x_f, x_ref = x_ref, u_ref = u_ref)
    
    dbfile = open(r'C:\Users\thatf\OneDrive\Documents\ASA\PSP-ASA-GTOC12-Problem\CVXPyGEN\LowThrustGTOC12\Earth2Ast_prob_FOH', 'ab')
    
    # source, destination
    pickle.dump(problem, dbfile)                    
    dbfile.close()


# Set parameters
#Ak_param.value = A_k[:, :, 0:N]
#Bk_param.value = B_k[:, :, 0:N]
#ck_param.value = c_k[:, :, 0:N]

# Set parameters
for k in range(N):
    problem.param_dict["Ak_" + str(k)].value = A_k[:, :, k]
    problem.param_dict["Bk_minus_" + str(k)].value = B_k_minus[:, :, k]
    problem.param_dict["Bk_plus_" + str(k)].value = B_k_plus[:, :, k]

problem.param_dict["ck"].value = c_k[:, 0, 0:N]

problem.param_dict["x_0"].value = x_0
problem.param_dict["x_f"].value = x_f

problem.param_dict["x_ref"].value = x_ref
problem.param_dict["u_ref"].value = u_ref
#problem.param_dict["p_ref"].value = p_ref

## Solve
#t0 = time.time()
#val = problem.solve(solver = "Clarabel", verbose = False)#solver = "ECOS")
#t1 = time.time()
#print('\nCVXPY Clarabel\nSolve time: %.3f ms with %.3f' % (1000 * (t1 - t0), val))
# 
# t0 = time.time()
# val = problem.solve(solver = "ECOS", verbose = False)#solver = "ECOS")
# t1 = time.time()
# print('\nCVXPY ECOS\nSolve time: %.3f ms with %.3f' % (1000 * (t1 - t0), val))

#t0 = time.time() 
#val = problem.solve(solver = "QOCO", verbose = True)#solver = "ECOS")
#t1 = time.time()
#print('\nCVXPY QOCO\nSolve time: %.3f ms with %.3f' % (1000 * (t1 - t0), val)) # don't know why QOCO is so slow for this... :(

#CVXPyGEN/LowThrustGTOC12/
cpg.generate_code(problem, code_dir='Earth2Ast_fixed_FOH_PTR_ECOS', solver = "ECOS")
#cpg.generate_code(problem, code_dir='Ast2Ast_fixed_FOH_PTR_QOCO', solver = "QOCO")
#cpg.generate_code(problem, code_dir='Ast2Ast_fixed_FOH_PTR_SCS', solver = "SCS")
# 
# 
from Earth2Ast_fixed_FOH_PTR_ECOS.cpg_solver import cpg_solve
# 
problem.register_solve('cpg', cpg_solve)
# 
# 
t0 = time.time()
val = problem.solve(method='cpg')
t1 = time.time()
#print('\ncvxpy ecos_gen \nsolve time: %.3f ms with %.3f and %.5f ms solve' % (1000 * (t1 - t0), val, 1000 * problem.solution.attr["solve_time"]))

# Extract Solution
X_sol = problem.var_dict['X'].value
U_sol = problem.var_dict['U'].value
p_sol = problem.var_dict['p'].value

eta = problem.var_dict['eta'].value
V = problem.var_dict['V'].value
v_0 = problem.var_dict['v_0'].value
v_N = problem.var_dict['v_N'].value

solve_status = problem.status

#dyn_err = np.zeros([nx, N])
#dyn_err_ref = np.zeros([nx, N])
#for k in range(N):
#    dyn_err[:, k] = X_sol[:, k + 1] - (A_k[:, :, k] @ X_sol[:, k] + B_k[:, :, k] @ U_sol[:, k] + c_k[:, 0, k])
#    dyn_err_ref[:, k] = x_ref[:, k + 1] - (A_k[:, :, k] @ x_ref[:, k] + B_k[:, :, k] @ u_ref[:, k] + c_k[:, 0, k])


# Debugs
#print(problem.var_dict['v_N'].value)
#print(virtual_control_cost_func_np(w_vc, problem.var_dict['V'].value, problem.var_dict['v_0'].value, problem.var_dict['v_N'].value))
#print(trust_region_cost_func(w_tr, problem.var_dict['eta'].value))