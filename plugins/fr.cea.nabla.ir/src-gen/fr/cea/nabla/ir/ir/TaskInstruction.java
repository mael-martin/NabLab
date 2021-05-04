/**
 */
package fr.cea.nabla.ir.ir;

import org.eclipse.emf.common.util.EList;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Task Instruction</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link fr.cea.nabla.ir.ir.TaskInstruction#getContent <em>Content</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.TaskInstruction#getInVars <em>In Vars</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.TaskInstruction#getOutVars <em>Out Vars</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.TaskInstruction#getMinimalInVars <em>Minimal In Vars</em>}</li>
 * </ul>
 *
 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskInstruction()
 * @model
 * @generated
 */
public interface TaskInstruction extends Instruction {
	/**
	 * Returns the value of the '<em><b>Content</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Content</em>' containment reference.
	 * @see #setContent(Instruction)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskInstruction_Content()
	 * @model containment="true" required="true"
	 * @generated
	 */
	Instruction getContent();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.TaskInstruction#getContent <em>Content</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Content</em>' containment reference.
	 * @see #getContent()
	 * @generated
	 */
	void setContent(Instruction value);

	/**
	 * Returns the value of the '<em><b>In Vars</b></em>' containment reference list.
	 * The list contents are of type {@link fr.cea.nabla.ir.ir.TaskDependencyVariable}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>In Vars</em>' containment reference list.
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskInstruction_InVars()
	 * @model containment="true" resolveProxies="true"
	 * @generated
	 */
	EList<TaskDependencyVariable> getInVars();

	/**
	 * Returns the value of the '<em><b>Out Vars</b></em>' containment reference list.
	 * The list contents are of type {@link fr.cea.nabla.ir.ir.TaskDependencyVariable}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Out Vars</em>' containment reference list.
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskInstruction_OutVars()
	 * @model containment="true" resolveProxies="true"
	 * @generated
	 */
	EList<TaskDependencyVariable> getOutVars();

	/**
	 * Returns the value of the '<em><b>Minimal In Vars</b></em>' containment reference list.
	 * The list contents are of type {@link fr.cea.nabla.ir.ir.TaskDependencyVariable}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Minimal In Vars</em>' containment reference list.
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTaskInstruction_MinimalInVars()
	 * @model containment="true" resolveProxies="true"
	 * @generated
	 */
	EList<TaskDependencyVariable> getMinimalInVars();

} // TaskInstruction
