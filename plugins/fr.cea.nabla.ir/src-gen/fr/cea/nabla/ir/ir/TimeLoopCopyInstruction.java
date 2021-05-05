/**
 */
package fr.cea.nabla.ir.ir;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Time Loop Copy Instruction</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link fr.cea.nabla.ir.ir.TimeLoopCopyInstruction#getContent <em>Content</em>}</li>
 * </ul>
 *
 * @see fr.cea.nabla.ir.ir.IrPackage#getTimeLoopCopyInstruction()
 * @model
 * @generated
 */
public interface TimeLoopCopyInstruction extends Instruction {
	/**
	 * Returns the value of the '<em><b>Content</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Content</em>' containment reference.
	 * @see #setContent(TimeLoopCopy)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getTimeLoopCopyInstruction_Content()
	 * @model containment="true" resolveProxies="true"
	 * @generated
	 */
	TimeLoopCopy getContent();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.TimeLoopCopyInstruction#getContent <em>Content</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Content</em>' containment reference.
	 * @see #getContent()
	 * @generated
	 */
	void setContent(TimeLoopCopy value);

} // TimeLoopCopyInstruction
