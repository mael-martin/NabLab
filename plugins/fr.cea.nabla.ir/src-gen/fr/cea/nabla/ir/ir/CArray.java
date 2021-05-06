/**
 */
package fr.cea.nabla.ir.ir;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>CArray</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link fr.cea.nabla.ir.ir.CArray#getPrimitive <em>Primitive</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.CArray#getSize <em>Size</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.CArray#isStatic <em>Static</em>}</li>
 *   <li>{@link fr.cea.nabla.ir.ir.CArray#getDefaultValue <em>Default Value</em>}</li>
 * </ul>
 *
 * @see fr.cea.nabla.ir.ir.IrPackage#getCArray()
 * @model
 * @generated
 */
public interface CArray extends IrType {
	/**
	 * Returns the value of the '<em><b>Primitive</b></em>' attribute.
	 * The literals are from the enumeration {@link fr.cea.nabla.ir.ir.PrimitiveType}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Primitive</em>' attribute.
	 * @see fr.cea.nabla.ir.ir.PrimitiveType
	 * @see #setPrimitive(PrimitiveType)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getCArray_Primitive()
	 * @model
	 * @generated
	 */
	PrimitiveType getPrimitive();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.CArray#getPrimitive <em>Primitive</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Primitive</em>' attribute.
	 * @see fr.cea.nabla.ir.ir.PrimitiveType
	 * @see #getPrimitive()
	 * @generated
	 */
	void setPrimitive(PrimitiveType value);

	/**
	 * Returns the value of the '<em><b>Size</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Size</em>' attribute.
	 * @see #setSize(int)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getCArray_Size()
	 * @model
	 * @generated
	 */
	int getSize();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.CArray#getSize <em>Size</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Size</em>' attribute.
	 * @see #getSize()
	 * @generated
	 */
	void setSize(int value);

	/**
	 * Returns the value of the '<em><b>Static</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Static</em>' attribute.
	 * @see #setStatic(boolean)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getCArray_Static()
	 * @model
	 * @generated
	 */
	boolean isStatic();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.CArray#isStatic <em>Static</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Static</em>' attribute.
	 * @see #isStatic()
	 * @generated
	 */
	void setStatic(boolean value);

	/**
	 * Returns the value of the '<em><b>Default Value</b></em>' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Default Value</em>' containment reference.
	 * @see #setDefaultValue(Expression)
	 * @see fr.cea.nabla.ir.ir.IrPackage#getCArray_DefaultValue()
	 * @model containment="true"
	 * @generated
	 */
	Expression getDefaultValue();

	/**
	 * Sets the value of the '{@link fr.cea.nabla.ir.ir.CArray#getDefaultValue <em>Default Value</em>}' containment reference.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Default Value</em>' containment reference.
	 * @see #getDefaultValue()
	 * @generated
	 */
	void setDefaultValue(Expression value);

} // CArray
